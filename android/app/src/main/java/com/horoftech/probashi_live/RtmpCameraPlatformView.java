package com.horoftech.probashi_live;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.view.TextureView;
import android.widget.FrameLayout;

import cn.nodemedia.NodePublisher;
import io.flutter.plugin.platform.PlatformView;

public class RtmpCameraPlatformView implements PlatformView {
    private final FrameLayout container;
    private boolean isFrontCamera = true;
    private boolean isVideoEnabled = true;
    private boolean isAudioEnabled = true;
   private final TextureView textureView;
    private final NodePublisher publisher;

    private Context unwrapToActivity(Context context) {
        while (context instanceof android.content.ContextWrapper) {
            if (context instanceof android.app.Activity) {
                return context;
            }
            context = ((android.content.ContextWrapper) context).getBaseContext();
        }
        return context;
    }

    public RtmpCameraPlatformView(Context context) {

        Context realContext = unwrapToActivity(context);

        if (!(realContext instanceof androidx.lifecycle.LifecycleOwner)) {
            throw new IllegalStateException("Context must be a LifecycleOwner");
        }
        textureView = new TextureView(realContext);

        container = new FrameLayout(realContext);
        container.addView(textureView);
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
        );
        publisher = new NodePublisher(realContext, "");
        container.setLayoutParams(params);
        publisher.attachView(container);

      container.post(new Runnable() {
          @Override
          public void run() {
              publisher.setAudioCodecParam(NodePublisher.NMC_CODEC_ID_AAC, NodePublisher.NMC_PROFILE_AUTO, 48000, 1, 64_000);
              publisher.setVideoOrientation(NodePublisher.VIDEO_ORIENTATION_PORTRAIT);
              publisher.setVideoCodecParam(NodePublisher.NMC_CODEC_ID_H264, NodePublisher.NMC_PROFILE_AUTO, 480, 854, 30, 1_000_000);
              // make sure view is attached
              publisher.openCamera(true);
          }
      });


//        new Handler(Looper.getMainLooper()).postDelayed(() -> {
//          // safe to open camera after small delay
//        }, 200);

    }
    //b3e36J4b
    //St754e55

    public void startStream(String url) {
        publisher.start(url);
    }

    public void stopStream() {
        publisher.stop();
        publisher.closeCamera();
    }

    public void toggleCamera() {
        publisher.switchCamera();
    }


    public void toggleVideo() {
        if (isVideoEnabled) {
            publisher.closeCamera();
        } else {
            publisher.openCamera(isFrontCamera);
        }
        isVideoEnabled = !isVideoEnabled;
    }

    public void toggleAudio() {
        if (isAudioEnabled) {
            publisher.setVolume(0); // mute
        } else {
            publisher.setVolume(100); // unmute
        }
        isAudioEnabled = !isAudioEnabled;
    }

    @Override
    public FrameLayout getView() {
        return container;
    }

    @Override
    public void dispose() {
        if(publisher!=null){
            publisher.detachView();
            publisher.closeCamera();
            publisher.stop();
        }
    }
}
