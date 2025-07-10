package com.horoftech.probashi_live;


import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "rtmp_channel";
    private RtmpCameraPlatformView rtmpCameraPlatformView;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Register PlatformView
        flutterEngine.getPlatformViewsController()
                .getRegistry()
                .registerViewFactory("rtmp_camera_view", new RtmpCameraPlatformViewFactory());

        // Setup MethodChannel to control streaming
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            switch (call.method) {
                                case "startStream":
                                    String url = call.argument("url");
                                    if (rtmpCameraPlatformView == null) {
                                        rtmpCameraPlatformView = new RtmpCameraPlatformView(MainActivity.this);
                                    }
                                    rtmpCameraPlatformView.startStream(url);
                                    result.success("started");
                                    break;
                                case "stopStream":
                                    if (rtmpCameraPlatformView != null) {
                                        rtmpCameraPlatformView.stopStream();
                                    }
                                    result.success("stopped");
                                    break;
                                case "toggleCamera":
                                    rtmpCameraPlatformView.toggleCamera();
                                    result.success("camera toggled");
                                    break;
                                case "toggleVideo":
                                    rtmpCameraPlatformView.toggleVideo();
                                    result.success("video toggled");
                                    break;
                                case "toggleAudio":
                                    rtmpCameraPlatformView.toggleAudio();
                                    result.success("audio toggled");
                                    break;
                                default:
                                    result.notImplemented();
                                    break;
                            }
                        });
    }
}