package com.horoftech.probashi_live;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterFragmentActivity {

    private static final String CHANNEL = "rtmp_channel";

    private GenericStreamView genericStreamViewInstance;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "initialize":
                            if (genericStreamViewInstance == null) {
                                genericStreamViewInstance = new GenericStreamView(this);
                                flutterEngine.getPlatformViewsController()
                                        .getRegistry()
                                        .registerViewFactory("generic_stream_view",
                                                new GenericStreamViewFactory(genericStreamViewInstance));
                            }
                            result.success(null);
                            break;
                        case "startPreview":
                            genericStreamViewInstance.startPreview();
                            result.success(null);
                            break;
                        case "stopPreview":
                            genericStreamViewInstance.stopPreview();
                            result.success(null);
                            break;
                            case "toggleBeauty":
                            genericStreamViewInstance.toggleBeauty();
                            result.success(null);
                            break;
                        case "startStream":
                            String url = call.argument("url");
                            genericStreamViewInstance.startStream(url);
                            result.success(null);
                            break;
                        case "toggleCamera":
                            genericStreamViewInstance.toggleCamera();
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
