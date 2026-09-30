package com.hildors.hildors_cockpit

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Only the device socket uses Wi-Fi. Internet requests keep the system route. */
class DeviceWifiSocket(private val context: Context) {
    private val workers = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())
    private val sockets = ConcurrentHashMap.newKeySet<Socket>()
    private val listeners = ConcurrentHashMap.newKeySet<ServerSocket>()
    private val disposed = AtomicBoolean(false)

    fun open(host: String, port: Int, result: MethodChannel.Result) {
        workers.execute {
            var remote: Socket? = null
            var listener: ServerSocket? = null
            try {
                require(host.matches(Regex("[0-9.]+")) && port in 1..65535)
                val address = InetAddress.getByName(host)
                require(address.isSiteLocalAddress) { "Device address must be local" }
                val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val network = manager.allNetworks.firstOrNull { network ->
                    manager.getNetworkCapabilities(network)?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true &&
                    manager.getLinkProperties(network)?.routes?.any { it.matches(address) } == true
                } ?: throw IllegalStateException("Device Wi-Fi is not connected")
                val device = network.socketFactory.createSocket()
                remote = device
                sockets.add(device)
                if (disposed.get()) throw IllegalStateException("Closed")
                device.tcpNoDelay = true
                device.connect(InetSocketAddress(address, port), 5000)
                val server = ServerSocket(0, 1, InetAddress.getByName("127.0.0.1"))
                listener = server
                listeners.add(server)
                server.soTimeout = 5000
                if (disposed.get()) throw IllegalStateException("Closed")
                main.post { result.success(server.localPort) }
                // Dart receives an ordinary byte stream. No protocol bytes added.
                workers.execute {
                    var local: Socket? = null
                    try {
                        val peer = server.accept()
                        local = peer
                        sockets.add(peer)
                        server.close()
                        listeners.remove(server)
                        peer.tcpNoDelay = true
                        val closed = AtomicBoolean(false)
                        fun closePair() {
                            if (closed.compareAndSet(false, true)) {
                                runCatching { peer.close() }
                                runCatching { device.close() }
                                sockets.remove(peer)
                                sockets.remove(device)
                            }
                        }
                        workers.execute {
                            try { peer.getInputStream().copyTo(device.getOutputStream(), 32768) }
                            catch (_: Exception) {} finally { closePair() }
                        }
                        try { device.getInputStream().copyTo(peer.getOutputStream(), 32768) }
                        finally { closePair() }
                    } catch (_: Exception) {
                        runCatching { local?.close() }
                        runCatching { device.close() }
                        local?.let { sockets.remove(it) }
                        sockets.remove(device)
                    } finally {
                        runCatching { server.close() }
                        listeners.remove(server)
                    }
                }
            } catch (error: Exception) {
                remote?.let { runCatching { it.close() }; sockets.remove(it) }
                listener?.let { runCatching { it.close() }; listeners.remove(it) }
                main.post { result.error("wifi_socket_failed", error.javaClass.simpleName, null) }
            }
        }
    }
    fun close() {
        disposed.set(true)
        listeners.forEach { runCatching { it.close() } }
        sockets.forEach { runCatching { it.close() } }
        workers.shutdownNow()
    }
}
