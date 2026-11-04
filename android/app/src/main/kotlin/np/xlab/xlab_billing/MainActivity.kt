package np.xlab.xlab_billing

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var usbManager: UsbManager? = null
    private var connection: UsbDeviceConnection? = null
    private var endpoint: UsbEndpoint? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usbManager = getSystemService(Context.USB_SERVICE) as? UsbManager
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "usb_printer")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "listDevices" -> {
                    val manager = usbManager
                    if (manager == null) {
                        result.error("usb_error", "UsbManager unavailable", null)
                    } else {
                        val devices = ArrayList<Map<String, Any?>>()
                        for ((_, device) in manager.deviceList) {
                            if (!looksLikePrinter(device)) continue
                            devices.add(
                                hashMapOf<String, Any?>(
                                    "vendorId" to device.vendorId,
                                    "productId" to device.productId,
                                    // Prefer the real USB device name (product
                                    // string); fall back to the raw bus path
                                    // (e.g. /dev/bus/usb/001/002) when the
                                    // descriptor carries no name.
                                    "deviceName" to (
                                        device.productName?.takeIf { it.isNotBlank() }
                                            ?: device.deviceName
                                            ?: ""
                                        ),
                                    "hasPermission" to manager.hasPermission(device),
                                ),
                            )
                        }
                        result.success(devices)
                    }
                }
                "hasPermission" -> {
                    val ok = usbManager?.hasPermission(findDevice(call)) ?: false
                    result.success(ok)
                }
                "requestPermission" -> {
                    val device = findDevice(call)
                    val manager = usbManager
                    if (device == null || manager == null) {
                        result.success(false)
                    } else if (manager.hasPermission(device)) {
                        // Already granted (persisted from an earlier session):
                        // the system may never send the permission broadcast
                        // again, so resolve immediately instead of hanging.
                        result.success(true)
                    } else {
                        // Never let a stale pending result swallow the new one.
                        MainActivity.pendingResult?.success(false)
                        MainActivity.pendingResult = result
                        MainActivity.pendingDevice = device
                        val actionIntent = Intent(USB_DEVICE_PERMISSION_ACTION).apply {
                            data = Uri.parse("usb/${device.vendorId}/${device.productId}")
                        }
                        // On Android 12+ the reply PendingIntent must be MUTABLE:
                        // with FLAG_IMMUTABLE the system cannot attach
                        // EXTRA_PERMISSION_GRANTED, so a granted dialog read back
                        // as "denied" and the device list never refreshed.
                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this@MainActivity,
                            REQUEST_CODE_USB_PERMISSION,
                            actionIntent,
                            flags,
                        )
                        manager.requestPermission(device, pendingIntent)
                    }
                }
                "open" -> {
                    val vendorId = call.argument<Int>("vendorId") ?: -1
                    val productId = call.argument<Int>("productId") ?: -1
                    result.success(openDeviceConnection(vendorId, productId))
                }
                "write" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val written =
                        if (bytes == null || bytes.isEmpty()) {
                            -1
                        } else {
                            val conn = connection
                            val ep = endpoint
                            if (conn == null || ep == null) {
                                -1
                            } else {
                                try {
                                    // 4-arg bulkTransfer is (endpoint, buffer, length, timeoutMs).
                                    conn.bulkTransfer(ep, bytes, bytes.size, USB_WRITE_TIMEOUT_MS)
                                } catch (e: Exception) {
                                    -1
                                }
                            }
                        }
                    result.success(written)
                }
                "close" -> {
                    closeConnection()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerReceiver(
            permissionReceiver,
            IntentFilter(USB_DEVICE_PERMISSION_ACTION),
            Context.RECEIVER_NOT_EXPORTED,
        )
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(permissionReceiver)
        } catch (_: Exception) {
        }
        closeConnection()
        super.onDestroy()
    }

    /// VID/PID pairs from the printer vendor's USB SDK demo (Android SDK/USBDEMO).
    /// These receipt boards do NOT advertise the USB printer class at device
    /// level (they report class 0 / 2 / 0xFF), so class-only filtering by
    /// definition missed them — exactly the "printer not detected" symptom.
    private val vendorPrinterIds: List<Pair<Int, Int>> = listOf(
        0x1CBE to 0x0003,
        0x1CB0 to 0x0003,
        0x0483 to 0x5740,
        0x0493 to 0x8760,
        0x0416 to 0x5011,
        0x0416 to 0xAABB,
    )

    private fun isVendorPrinter(device: UsbDevice): Boolean =
        vendorPrinterIds.any { it.first == device.vendorId && it.second == device.productId }

    /// A device counts as a printer when its VID/PID is in the vendor table,
    /// when the device itself reports printer/mass-storage class, or when any
    /// interface exposes the shape of an ESC/POS board: printer / mass-storage /
    /// CDC-data / vendor-specific / per-interface class with a bulk OUT endpoint.
    private fun looksLikePrinter(device: UsbDevice): Boolean {
        if (isVendorPrinter(device)) return true
        if (device.deviceClass == UsbConstants.USB_CLASS_PRINTER ||
            device.deviceClass == UsbConstants.USB_CLASS_MASS_STORAGE
        ) {
            return true
        }
        return hasPrintableInterface(device)
    }

    private fun hasPrintableInterface(device: UsbDevice): Boolean {
        for (i in 0 until device.interfaceCount) {
            val iface = device.getInterface(i)
            val plausible = iface.interfaceClass == UsbConstants.USB_CLASS_PRINTER ||
                iface.interfaceClass == UsbConstants.USB_CLASS_MASS_STORAGE ||
                iface.interfaceClass == UsbConstants.USB_CLASS_CDC_DATA ||
                iface.interfaceClass == UsbConstants.USB_CLASS_VENDOR_SPEC ||
                iface.interfaceClass == UsbConstants.USB_CLASS_PER_INTERFACE
            if (!plausible) continue
            for (j in 0 until iface.endpointCount) {
                val e = iface.getEndpoint(j)
                if (e.direction == UsbConstants.USB_DIR_OUT &&
                    e.type == UsbConstants.USB_ENDPOINT_XFER_BULK
                ) {
                    return true
                }
            }
        }
        return false
    }

    private fun findDevice(call: MethodCall): UsbDevice? {
        val vendorId = call.argument<Int>("vendorId") ?: -1
        val productId = call.argument<Int>("productId") ?: -1
        val manager = usbManager ?: return null
        return manager.deviceList.values.firstOrNull {
            it.vendorId == vendorId && it.productId == productId
        }
    }

    private fun openDeviceConnection(vendorId: Int, productId: Int): Boolean {
        closeConnection()
        val manager = usbManager ?: return false
        val device = manager.deviceList.values.firstOrNull {
            it.vendorId == vendorId && it.productId == productId
        } ?: return false
        val conn = manager.openDevice(device) ?: return false
        // Data goes out through the interface that carries a bulk OUT endpoint.
        // CDC-style boards (e.g. 0483:5740) put it on interface 1 and keep the
        // control channel on interface 0 — claiming interface 0 unconditionally
        // made writes fail even after successful detection.
        for (i in 0 until device.interfaceCount) {
            val iface = device.getInterface(i)
            var ep: UsbEndpoint? = null
            for (j in 0 until iface.endpointCount) {
                val e = iface.getEndpoint(j)
                if (e.direction == UsbConstants.USB_DIR_OUT &&
                    e.type == UsbConstants.USB_ENDPOINT_XFER_BULK
                ) {
                    ep = e
                    break
                }
            }
            if (ep == null) continue
            if (!conn.claimInterface(iface, true)) continue
            connection = conn
            endpoint = ep
            return true
        }
        conn.close()
        return false
    }

    private fun closeConnection() {
        val conn = connection
        connection = null
        endpoint = null
        if (conn != null) {
            try {
                conn.close()
            } catch (_: Exception) {
            }
        }
    }

    private val permissionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            // Authoritative grant = the reply extra when present, else the live
            // permission state. The extra is missing when the reply
            // PendingIntent was immutable (pre-fix installs) or dropped by an
            // OEM quirk; usbManager.hasPermission() cannot lie after a grant.
            val device = MainActivity.pendingDevice
            val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false) ||
                (device != null && usbManager?.hasPermission(device) == true)
            val result = MainActivity.pendingResult
            MainActivity.pendingResult = null
            MainActivity.pendingDevice = null
            result?.success(granted)
        }
    }

    public companion object {
        private const val USB_DEVICE_PERMISSION_ACTION = "android.hardware.usb.action.USB_DEVICE_PERMISSION"
        private const val REQUEST_CODE_USB_PERMISSION = 0x0B0B
        private const val USB_WRITE_TIMEOUT_MS = 5000

        @Volatile
        var pendingResult: MethodChannel.Result? = null

        @Volatile
        var pendingDevice: UsbDevice? = null
    }
}
