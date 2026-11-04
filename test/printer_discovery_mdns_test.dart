// LAN discovery name resolution: DNS-SD/mDNS frame parsing, query building
// and host→name mapping. Pure byte tests — no sockets involved.
//
// The sweep that feeds this (PrinterDiscoveryService.resolveNames) is wired
// into scanSubnet: hosts that answered the raw 9100 probe get a friendly
// name when the LAN runs Bonjour/mDNS responders, or stay nameless and the
// tile keeps the ip + port line.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:xlab_billing/shared/services/printer_discovery.dart';

Uint8List _encodeName(String name) {
  final b = BytesBuilder();
  for (final label in name.split('.')) {
    final enc = utf8.encode(label);
    if (enc.isEmpty) continue;
    b.addByte(enc.length);
    b.add(enc);
  }
  b.addByte(0);
  return b.toBytes();
}

Uint8List _frame(List<Uint8List> rrs) {
  final b = BytesBuilder();
  final h = ByteData(12)
    ..setUint16(0, 0x1234)
    ..setUint16(2, 0x8400)
    ..setUint16(10, rrs.length); // AR-count
  b.add(h.buffer.asUint8List());
  for (final rr in rrs) {
    b.add(rr);
  }
  return b.toBytes();
}

Uint8List _rr(String owner, int type, Uint8List rdata) {
  final b = BytesBuilder();
  b.add(_encodeName(owner));
  final fixed = ByteData(8)
    ..setUint16(0, type)
    ..setUint16(2, 0x0001) // class IN
    ..setUint32(4, 120); // ttl
  b.add(fixed.buffer.asUint8List());
  final rdl = ByteData(2)..setUint16(0, rdata.length);
  b.add(rdl.buffer.asUint8List());
  b.add(rdata);
  return b.toBytes();
}

Uint8List _srv(int port, String target) {
  final b = BytesBuilder();
  final head = ByteData(6)
    ..setUint16(0, 0) // priority
    ..setUint16(2, 0) // weight
    ..setUint16(4, port);
  b.add(head.buffer.asUint8List());
  b.add(_encodeName(target));
  return b.toBytes();
}

void main() {
  test('mDNS parser maps service instance, A and reverse-PTR records', () {
    final frame = _frame([
      _rr('_pdl-datastream._tcp.local', 12,
          _encodeName('MINI-POS 12._pdl-datastream._tcp.local')),
      _rr('MINI-POS 12._pdl-datastream._tcp.local', 33,
          _srv(9100, 'minipos-1234.local')),
      _rr('minipos-1234.local', 1, Uint8List.fromList([10, 0, 0, 7])),
      _rr('7.0.0.10.in-addr.arpa', 12, _encodeName('minipos-1234.local')),
    ]);
    final rec = PrinterDiscoveryService.parseMdnsResponse(frame);
    expect(rec.instanceByFqdn['minipos-1234.local'], 'MINI-POS 12',
        reason: 'via SRV owner label');
    expect(rec.instanceByFqdn['mini-pos 12._pdl-datastream._tcp.local'],
        'MINI-POS 12',
        reason: 'via PTR rdata first label');
    expect(rec.ipByFqdn['minipos-1234.local'], '10.0.0.7');
    expect(rec.fqdnByReverseArpa['7.0.0.10.in-addr.arpa'],
        'minipos-1234.local');
  });

  test('parser follows compression pointers into the question section', () {
    // The built query carries the question `_ipp._tcp.local.` whose encoded
    // name sits at offset 12; an answer can reference it via pointer 0xC00C.
    final q = PrinterDiscoveryService.buildServiceQuery(
        0x0042, '_ipp._tcp.local.');
    final b = BytesBuilder()..add(q);
    b.addByte(0xC0);
    b.addByte(12);
    final rest = ByteData(10)
      ..setUint16(0, 1) // A
      ..setUint16(2, 0x0001)
      ..setUint32(4, 60) // ttl
      ..setUint16(8, 4); // rdlength
    b.add(rest.buffer.asUint8List());
    b.add(Uint8List.fromList([192, 168, 5, 5]));
    final patched = Uint8List.fromList(b.toBytes());
    patched[7] = 1; // AN-count = 1
    final rec = PrinterDiscoveryService.parseMdnsResponse(patched);
    expect(rec.ipByFqdn['_ipp._tcp.local'], '192.168.5.5');
  });

  test('parser tolerates malformed, empty and oversized frames', () {
    expect(PrinterDiscoveryService.parseMdnsResponse(const []).isEmpty,
        isTrue);
    expect(PrinterDiscoveryService.parseMdnsResponse(List<int>.filled(15, 0))
        .isEmpty, isTrue);
    expect(
        PrinterDiscoveryService.parseMdnsResponse(
            List<int>.filled(8192, 0)).isEmpty,
        isTrue);
    // rdlength claims 4 bytes of address but the frame is cut short:
    // the walk must keep the empty records instead of throwing.
    final cut = _frame([
      _rr('minipos.local', 1, Uint8List.fromList([10, 0, 0, 7])),
    ]);
    expect(
        PrinterDiscoveryService.parseMdnsResponse(
            cut.sublist(0, cut.length - 1)).isEmpty,
        isTrue);
  });

  test('query builders produce PTR + QU-class questions', () {
    final service = PrinterDiscoveryService.buildServiceQuery(
        0xBEEF, '_printer._tcp.local.');
    expect(service[0], 0xBE);
    expect(service[1], 0xEF);
    expect(service[2], 0); // flags: query
    expect(service[4], 0); // QDCOUNT = 1
    expect(service[5], 1);
    // last four bytes: QTYPE 12 (PTR), QCLASS 0x8001 (IN | QU)
    expect(service.sublist(service.length - 4), [0, 12, 0x80, 0x01]);
    expect(
        PrinterDiscoveryService.buildReverseQuery(1, '192.168.1.100').$2,
        '100.1.168.192.in-addr.arpa');
  });

  test('namesForHosts: instance wins, .local label fallback, unknown absent',
      () {
    final r = DnsSdRecords()
      ..ipByFqdn['minipos-1234.local'] = '10.0.0.7'
      ..ipByFqdn['printer-hall-a.local'] = '10.0.0.9'
      ..instanceByFqdn['minipos-1234.local'] = 'MINI-POS 12'
      ..fqdnByReverseArpa['11.0.0.10.in-addr.arpa'] = 'nether-group-2.local';
    final names = PrinterDiscoveryService.namesForHosts(
      r,
      const ['10.0.0.7', '10.0.0.9', '10.0.0.11', '10.0.0.12'],
      const {
        '10.0.0.7': '7.0.0.10.in-addr.arpa',
        '10.0.0.9': '9.0.0.10.in-addr.arpa',
        '10.0.0.11': '11.0.0.10.in-addr.arpa',
        '10.0.0.12': '12.0.0.10.in-addr.arpa',
      },
    );
    expect(names, {
      '10.0.0.7': 'MINI-POS 12',
      '10.0.0.9': 'printer-hall-a',
      '10.0.0.11': 'nether-group-2',
    });
  });
}
