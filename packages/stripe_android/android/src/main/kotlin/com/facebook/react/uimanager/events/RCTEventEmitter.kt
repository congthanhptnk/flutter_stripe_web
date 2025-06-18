package com.facebook.react.uimanager.events

import android.os.Handler
import android.os.Looper
import com.facebook.react.bridge.ReadableMap
import io.flutter.plugin.common.MethodChannel

class RCTEventEmitter(private val channel: MethodChannel) {
    private val uiThread = Handler(Looper.getMainLooper())

    fun receiveEvent(viewTag: Any, eventName: String, serializeEventData: ReadableMap?) {
        uiThread.post { channel.invokeMethod(eventName, serializeEventData) }
    }
}
