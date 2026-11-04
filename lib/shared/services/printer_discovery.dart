/// LAN discovery: find likely thermal printers by scanning the local /24 on
/// the configured port (default 9100). No root permissions required.
///
/// Discovery is best-effort: some printers only respond after being "woken"
/// with a status request, and some networks block ARP/host discovery. Manual
/// entry always remains available.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/printer.dart';

/// Everything a parsed mDNS/DNS-SD response can tell us about printers.
///
/// Public and `@visibleForTesting`-parsed so the frame parser can be unit
/// tested without network sockets.
@visibleForTesting
class DnsSdRecords {
  bool get isEmpty =>
      instanceByFqdn.isEmpty && ipByFqdn.isEmpty && fqdnByReverseArpa.isEmpty;

  /// Device hostname fqdn → friendly instance name (PTR rdata of
  /// `_pdl-datastream._tcp`-class service points), e.g.
  /// `minipos-1234.local` → `MINI-POS-1234`.
  final instanceByFqdn = <String, String>{};

  /// Device hostname fqdn → A-record address, e.g. `minipos-1234.local` →
  /// `192.168.1.100`.
  final ipByFqdn = <String, String>{};

  /// Reverse PTR query name (`100.1.168.192.in-addr.arpa`) → announced device
  /// hostname (when a responder answers the reverse query).
  final fqdnByReverseArpa = <String, String>{};
}

class PrinterDiscoveryService {
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  /// Returns the local interface address (e.g. 192.168.1.23) or null.
  ///
  /// Prefers enumerating local interfaces (works without outbound internet
  /// access, which is common on receipt-printer LANs); falls back to probing
  /// a public host for networks where interface enumeration is unavailable.
  ///
  /// Loopback (127.x) is skipped: scanning 127.x would probe only the device
  /// itself and find nothing. Private ranges win because printers live there.
  Future<String?> localAddress() async {
    try {
      final candidates = <({String interfaceName, String address})>[];
      for (final interface in await NetworkInterface.list()) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            candidates.add((
              interfaceName: interface.name,
              address: address.address,
            ));
          }
        }
      }
      final picked = pickLanInterfaceAddress(candidates);
      if (picked != null) return picked;
    } catch (_) {
      // Fall through to the network probe.
    }
    try {
      final socket = await Socket.connect('223.5.5.5', 80, timeout: const Duration(seconds: 1));
      final addr = socket.address.address;
      socket.destroy();
      return addr;
    } catch (_) {
      return null;
    }
  }

  /// True for Android/Linux cellular data and VPN/tunnel interfaces that carry
  /// RFC 1918 IPv4 addresses (e.g. MediaTek `ccmni*` 10.x, Qualcomm `rmnet*`
  /// 10.x, VPN/tunnel `tun*` / `vgate*` 172.16-31.x) but are never the local
  /// receipt-printer LAN.
  @visibleForTesting
  static bool isCellularOrTunnelInterface(String name) {
    final n = name.toLowerCase();
    return n.startsWith('ccmni') ||
        n.startsWith('rmnet') ||
        n.startsWith('r_rmnet') ||
        n.startsWith('pdp') ||
        n.startsWith('svnet') ||
        n.startsWith('clat') ||
        n.startsWith('v4-') ||
        n.startsWith('tun') ||
        n.startsWith('tap') ||
        n.startsWith('ppp') ||
        n.startsWith('wg') ||
        n.startsWith('vgate') ||
        n.startsWith('dummy');
  }

  /// True for Wi-Fi / Ethernet LAN interfaces (`wlan0`, `eth0`, `en0`, etc.).
  @visibleForTesting
  static bool isPreferredLanInterface(String name) {
    final n = name.toLowerCase();
    return n.startsWith('wlan') ||
        n.startsWith('swlan') ||
        n.startsWith('wifi') ||
        n.startsWith('eth') ||
        n.startsWith('en') ||
        n.startsWith('ap');
  }

  /// Picks the local LAN IPv4 address from `(interfaceName, address)` pairs:
  /// prefers Wi-Fi/Ethernet interfaces (`wlan0`, `eth0`), skips cellular/VPN
  /// interfaces (`ccmni*`, `rmnet*`, `tun*`, `vgate*`), and delegates address
  /// priority to [pickLanAddress].
  @visibleForTesting
  static String? pickLanInterfaceAddress(
    Iterable<({String interfaceName, String address})> candidates,
  ) {
    final preferred = <String>[];
    final other = <String>[];
    for (final c in candidates) {
      if (isCellularOrTunnelInterface(c.interfaceName)) continue;
      if (isPreferredLanInterface(c.interfaceName)) {
        preferred.add(c.address);
      } else {
        other.add(c.address);
      }
    }
    return pickLanAddress(preferred) ?? pickLanAddress(other);
  }

  /// Pure pick from a list of IPv4 strings: first address of the private
  /// ranges (192.168/10/172.16-31), falling back to the first non-loopback
  /// address; null when everything is loopback.
  @visibleForTesting
  static String? pickLanAddress(Iterable<String> addresses) {
    String? fallback;
    for (final a in addresses) {
      if (a.startsWith('127.')) continue;
      final parts = a.split('.');
      final second = parts.length >= 2 ? int.tryParse(parts[1]) : null;
      final private = a.startsWith('192.168.') ||
          a.startsWith('10.') ||
          (a.startsWith('172.') && second != null && second >= 16 && second <= 31);
      if (private) return a;
      fallback ??= a;
    }
    return fallback;
  }

  // ---
  // Friendly-name resolution (best-effort):
  //
  // Cheap receipt boards accept raw socket data on port 9100 but expose no
  // identity in the standard ESC/POS profile. The portable name source is
  // mDNS/DNS-SD (Bonjour): boards with print services advertise
  // `_pdl-datastream` / `_ipp` / `_printer` whose PTR record carries the
  // human label. Queries go to the well-known multicast group as RFC 6762
  // *QU* questions (top bit of QCLASS set → unicast replies), so Android's
  // Wi-Fi multicast filter — the app holds no multicast lock — cannot
  // swallow the reply packets. Boards without Bonjour simply never answer
  // and the UI keeps ip + port.
  // ---

  static const _mdnsPort = 5353;
  static const _mdnsGroup = '224.0.0.251';
  static const _mdnsServiceTypes = [
    '_pdl-datastream._tcp.local.',
    '_ipp._tcp.local.',
    '_printer._tcp.local.',
  ];
  static const _sweepWindow = Duration(milliseconds: 900);

  /// One UDP sweep: sends the service queries plus one reverse PTR query per
  /// found host, collects answers for [window], maps results back to the
  /// hosts. Unresolvable hosts are absent from the returned map.
  Future<Map<String, String>> resolveNames(
    Iterable<String> hosts, {
    Duration window = _sweepWindow,
  }) async {
    RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
    } catch (_) {
      return const {};
    }
    final records = DnsSdRecords();
    final reverseQueryByHost = <String, String>{};
    var messageId = DateTime.now().millisecondsSinceEpoch & 0xFFFF;
    try {
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null || datagram.data.isEmpty) return;
        final parsed = parseMdnsResponse(datagram.data);
        records.instanceByFqdn.addAll(parsed.instanceByFqdn);
        records.ipByFqdn.addAll(parsed.ipByFqdn);
        records.fqdnByReverseArpa.addAll(parsed.fqdnByReverseArpa);
      });
      final group = InternetAddress(_mdnsGroup);
      for (final service in _mdnsServiceTypes) {
        socket.send(buildServiceQuery(++messageId, service), group, _mdnsPort);
      }
      for (final host in hosts.toSet()) {
        final (bytes, queryName) = buildReverseQuery(++messageId, host);
        reverseQueryByHost[host] = queryName;
        socket.send(bytes, group, _mdnsPort);
      }
      await Future<void>.delayed(window);
    } catch (_) {
      // Best-effort sweep: a transport failure still yields whatever arrived.
    } finally {
      socket.close();
    }
    return namesForHosts(records, hosts, reverseQueryByHost);
  }

  /// Pure naming pass: service PTR instance (row "MINI-POS-1234") wins, then
  /// the reverse-PTR device hostname's `.local` first label, then the A-record
  /// host label. Unknown hosts map to empty string.
  @visibleForTesting
  static Map<String, String> namesForHosts(
    DnsSdRecords records,
    Iterable<String> hosts,
    Map<String, String> reverseQueryByHost,
  ) {
    final names = <String, String>{};
    for (final host in hosts) {
      final deviceFqdns = records.ipByFqdn.entries
          .where((e) => e.value == host)
          .map((e) => e.key)
          .toList();
      final candidates = <String?>[
        for (final fq in deviceFqdns) records.instanceByFqdn[fq],
      ];
      final query = reverseQueryByHost[host];
      final reverseFqdn = query == null
          ? null
          : records.fqdnByReverseArpa[query.toLowerCase()];
      if (reverseFqdn != null) {
        candidates.add(records.instanceByFqdn[reverseFqdn.toLowerCase()]);
        if (reverseFqdn.toLowerCase().endsWith('.local')) {
          candidates.add(_firstLabel(reverseFqdn));
        }
      }
      candidates.addAll([
        for (final fq in deviceFqdns)
          fq.toLowerCase().endsWith('.local') ? _firstLabel(fq) : null,
      ]);
      final name = candidates.whereType<String>().firstWhere(
            (n) => n.trim().isNotEmpty,
            orElse: () => '',
          );
      if (name.trim().isNotEmpty) names[host] = name.trim();
    }
    return names;
  }

  static String? _firstLabel(String fqdn) {
    final i = fqdn.indexOf('.');
    if (i <= 0) return fqdn.isEmpty ? null : fqdn;
    return fqdn.substring(0, i);
  }

  /// Standard DNS question packet (RD=0). QCLASS `0x8001` = IN with the QU
  /// bit set so mDNS responders answer unicast directly, dodging Android's
  /// multicast receive filter.
  @visibleForTesting
  static Uint8List buildServiceQuery(int messageId, String serviceFqdn) =>
      _buildQuery(messageId, serviceFqdn);

  /// Same packet shape for `<rev-ip>.in-addr.arpa.` PTR; returns the bytes
  /// plus the exact query name used (no trailing dot, matching how answer
  /// owner names are joined by the parser).
  @visibleForTesting
  static (Uint8List, String) buildReverseQuery(int messageId, String host) {
    final queryName = '${host.split('.').reversed.join('.')}.in-addr.arpa';
    return (_buildQuery(messageId, queryName), queryName);
  }

  static Uint8List _buildQuery(int messageId, String name) {
    final b = BytesBuilder();
    final header = ByteData(12)
      ..setUint16(0, messageId)
      ..setUint16(2, 0) // flags: query, recursion not desired
      ..setUint16(4, 1); // one question
    b.add(header.buffer.asUint8List());
    for (final label in name.split('.')) {
      final encoded = utf8.encode(label);
      if (encoded.isEmpty || encoded.length > 63) continue;
      b.addByte(encoded.length);
      b.add(encoded);
    }
    b.addByte(0);
    final tail = ByteData(4)
      ..setUint16(0, 12) // QTYPE PTR
      ..setUint16(2, 0x8001); // QCLASS IN | QU
    b.add(tail.buffer.asUint8List());
    return b.toBytes();
  }

  /// Pure mDNS response parser: answers/additionals may be compressed, so
  /// name reads follow RFC 1035 §4.1.4 pointers. Bound-checked throughout;
  /// anything malformed stops the walk and keeps what parsed so far.
  @visibleForTesting
  static DnsSdRecords parseMdnsResponse(List<int> frame) {
    final records = DnsSdRecords();
    if (frame.length < 12 || frame.length > 4096) return records;
    try {
      var pos = 12;
      final questionCount = _u16(frame, 4);
      final rrCount = _u16(frame, 6) + _u16(frame, 8) + _u16(frame, 10);
      for (var q = 0; q < questionCount && pos < frame.length; q++) {
        final (_, int after) = _readName(frame, pos);
        pos = after + 4; // QTYPE + QCLASS
      }
      for (var rr = 0; rr < rrCount && pos + 10 <= frame.length; rr++) {
        final (labels, int afterOwner) = _readName(frame, pos);
        final owner = labels.join('.').toLowerCase();
        final type = _u16(frame, afterOwner);
        final rdl = _u16(frame, afterOwner + 8);
        final rdataEnd = afterOwner + 10 + rdl;
        if (rdataEnd > frame.length) return records;
        final rdata = frame.sublist(afterOwner + 10, rdataEnd);
        switch (type) {
          case 12: // PTR: rdata points at the referred-to name (device).
            // Compression pointers may reference the message header, so the
            // name is walked in the absolute frame, not the rdata sublist.
            final (target, _) = _readName(frame, afterOwner + 10);
            final fqdn = target.join('.').toLowerCase();
            if (fqdn.isEmpty) break;
            if (owner.endsWith('.in-addr.arpa')) {
              records.fqdnByReverseArpa[owner] = fqdn;
            } else if (target.isNotEmpty) {
              records.instanceByFqdn[fqdn] = target.first;
            }
          case 33: // SRV: owner (instance service) → device fqdn target
            if (rdl > 6) {
              final (target, _) = _readName(frame, afterOwner + 16);
              final fqdn = target.join('.').toLowerCase();
              if (fqdn.isNotEmpty && labels.isNotEmpty) {
                records.instanceByFqdn[fqdn] = labels.first;
              }
            }
          case 1: // A
            if (rdl == 4) {
              records.ipByFqdn[owner] = rdata.join('.');
            }
          case 28: // AAAA — IPv6 printers are out of scope for this scan
            break;
        }
        pos = rdataEnd;
      }
    } catch (_) {
      // Malformed frame: keep the records parsed so far.
    }
    return records;
  }

  static int _u16(List<int> b, int o) => (b[o] << 8) | b[o + 1];

  /// RFC 1035 name walk with pointer following; returns the (utf8-decoded)
  /// labels plus the position just after the name in the original buffer.
  static (List<String>, int) _readName(List<int> frame, int pos) {
    final labels = <String>[];
    var p = pos;
    int? endAfterJump;
    var jumps = 0;
    while (true) {
      if (p >= frame.length) return (labels, frame.length);
      final len = frame[p];
      if (len == 0) return (labels, endAfterJump ?? p + 1);
      if ((len & 0xC0) == 0xC0) {
        if (p + 1 >= frame.length) return (labels, frame.length);
        final target = ((len & 0x3F) << 8) | frame[p + 1];
        endAfterJump ??= p + 2;
        if (++jumps > 16) return (labels, frame.length);
        p = target;
        continue;
      }
      final end = p + 1 + len;
      if (end > frame.length) return (labels, frame.length);
      labels.add(utf8.decode(frame.sublist(p + 1, end), allowMalformed: true));
      p = end;
    }
  }

  /// Scans [fromIp]-[toIp] on [port] with [timeout] per attempt.
  ///
  /// After the port sweep, one bounded mDNS sweep resolves friendly printer
  /// names where the LAN supports it ([DiscoveredPrinter.name]); hosts that
  /// answer nothing report an empty name and the UI keeps ip + port.
  Future<List<DiscoveredPrinter>> scanSubnet({
    required String baseIp,
    required int port,
    int timeoutMs = 250,
    int concurrency = 24,
    void Function(int done, int total)? onProgress,
    bool Function()? shouldContinue,
  }) async {
    _cancelled = false;
    final parts = baseIp.split('.');
    if (parts.length != 4) throw ArgumentError('baseIp');
    final prefix = parts.sublist(0, 3).join('.');
    final results = <DiscoveredPrinter>[];
    const total = 254;
    var done = 0;

    Future<void> probe(int last) async {
      if (_cancelled || shouldContinue?.call() == false) return;
      final host = '$prefix.$last';
      try {
        final socket = await Socket.connect(
          host,
          port,
          timeout: Duration(milliseconds: timeoutMs),
        );
        socket.destroy();
        if (!_cancelled) {
          results.add(DiscoveredPrinter(host: host, port: port, name: ''));
        }
      } catch (_) {
        // closed/unreachable — not a printer on this port
      }
      if (onProgress != null) onProgress(++done, total);
    }

    final queue = [for (var i = 1; i <= 254; i++) i];
    while (queue.isNotEmpty) {
      final batch = <Future<void>>[];
      for (var i = 0; i < concurrency && queue.isNotEmpty; i++) {
        batch.add(probe(queue.removeAt(0)));
      }
      await Future.wait<void>(batch, eagerError: false);
      if (_cancelled) break;
    }
    if (results.isNotEmpty && !_cancelled) {
      // One bounded, network-wide mDNS sweep for the found hosts; the map
      // only carries hosts whose LAN resolved a friendly name.
      final names = await resolveNames(results.map((r) => r.host));
      if (!_cancelled && names.isNotEmpty) {
        for (var i = 0; i < results.length; i++) {
          results[i] = DiscoveredPrinter(
            host: results[i].host,
            port: results[i].port,
            name: names[results[i].host] ?? '',
          );
        }
      }
    }
    return results;
  }
}
