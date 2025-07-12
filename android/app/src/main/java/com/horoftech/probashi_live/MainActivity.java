package com.horoftech.probashi_live;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class MainActivity extends FlutterFragmentActivity {

    private static final String CHANNEL = "rtmp_channel";

    private GenericStreamView genericStreamViewInstance;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Create the native view instance here manually
        genericStreamViewInstance = new GenericStreamView(this);

        // Register factory that returns the existing instance
        flutterEngine.getPlatformViewsController()
                .getRegistry()
                .registerViewFactory("generic_stream_view", new GenericStreamViewFactory(genericStreamViewInstance));

        // Set up MethodChannel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (genericStreamViewInstance == null) {
                        result.error("NO_VIEW", "GenericStreamView not initialized", null);
                        return;
                    }

                    switch (call.method) {
                        case "startStream":
                            String url = call.argument("url");
                            genericStreamViewInstance.startStream(url);
                            result.success(null);
                            break;

                        case "stopStream":
                            genericStreamViewInstance.stopStream();
                            result.success(null);
                            break;

                        case "switchCamera":
                            genericStreamViewInstance.switchCamera();
                            result.success(null);
                            break;

                        case "mute":
                            genericStreamViewInstance.mute();
                            result.success(null);
                            break;

                        case "unmute":
                            genericStreamViewInstance.unmute();
                            result.success(null);
                            break;

                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }
}
