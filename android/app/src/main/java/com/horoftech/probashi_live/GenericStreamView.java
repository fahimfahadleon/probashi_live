package com.horoftech.probashi_live;

import android.app.Activity;
import android.content.Context;
import android.media.MediaRecorder;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.Toast;
import com.pedro.encoder.input.sources.audio.AudioSource;
import android.util.DisplayMetrics;
import android.view.WindowManager;

import com.pedro.encoder.input.sources.video.Camera2Source;
import com.pedro.extrasources.CameraXSource;
import com.pedro.encoder.input.sources.video.Camera1Source;
import com.pedro.encoder.input.sources.video.VideoSource;

import androidx.annotation.NonNull;
import com.pedro.encoder.input.sources.audio.MicrophoneSource;

import com.pedro.common.ConnectChecker;
import com.pedro.library.generic.GenericStream;
import com.pedro.library.util.BitrateAdapter;
import io.flutter.plugin.platform.PlatformView;

public class GenericStreamView extends FrameLayout implements PlatformView, ConnectChecker {

    private final SurfaceView surfaceView;
    private final GenericStream genericStream;
    private final BitrateAdapter bitrateAdapter;
    private final CameraXSource cameraXSource;
    private final MicrophoneSource microphoneSource;
    Context context;

    public GenericStreamView(@NonNull Context context) {
        super(context);
        this.context = context;
        surfaceView = new SurfaceView(context);
        addView(surfaceView);
        cameraXSource = new CameraXSource(context);
        microphoneSource = new MicrophoneSource();

        genericStream = new GenericStream(context, this);


        bitrateAdapter = new BitrateAdapter(bitrate -> genericStream.setVideoBitrateOnFly(bitrate));
        bitrateAdapter.setMaxBitrate(1200_000 + 128_000);

        surfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                if (!genericStream.isOnPreview()) {
                    genericStream.startPreview(surfaceView);
                }
            }

            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {

               Log.e("width",String.valueOf(width));
               Log.e("height",String.valueOf(width));
                genericStream.getGlInterface().setPreviewResolution(width, height);
            }

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                if (genericStream.isOnPreview()) {
                    genericStream.stopPreview();
                }
            }
        });

        DisplayMetrics metrics = new DisplayMetrics();
        ((Activity)context).getWindowManager().getDefaultDisplay().getRealMetrics(metrics);
        int width = metrics.widthPixels;
        int height = metrics.heightPixels;

        boolean prepared =  genericStream.prepareVideo(width,height,1200_000,60,0,90)
                && genericStream.prepareAudio(
                44100,     // sampleRate
                true,      // isStereo
                128000,    // bitrate
                true,     // echoCanceler
                true      // noiseSuppressor
        );
        if (!prepared) {
            Log.e("error","could not prepare video or audio");
            return;
        }



    }

    public void startStream(String url) {
        Toast.makeText(context, "start stream called", Toast.LENGTH_SHORT).show();
        genericStream.startStream(url);
    }

    public void stopStream() {
        genericStream.stopStream();
    }

    public void switchCamera() {
        VideoSource videoSource = genericStream.getVideoSource();

        if (videoSource instanceof CameraXSource) {
            ((CameraXSource) videoSource).switchCamera();
        } else if (videoSource instanceof Camera1Source) {
            ((Camera1Source) videoSource).switchCamera();
        } else if (videoSource instanceof Camera2Source) {
            ((Camera2Source) videoSource).switchCamera();
        }
        Toast.makeText(context, "switch camera called", Toast.LENGTH_SHORT).show();
    }

    public void release() {
        genericStream.release();
    }

    public void mute() {
        AudioSource source = genericStream.getAudioSource();
        if(source instanceof MicrophoneSource){
            ((MicrophoneSource) source).mute();
        }
        Toast.makeText(context, "microphone mute called", Toast.LENGTH_SHORT).show();
    }

    public void unmute() {
        AudioSource source = genericStream.getAudioSource();
        if(source instanceof MicrophoneSource){
            ((MicrophoneSource) source).unMute();
        }
        Toast.makeText(context, "microphone unmute called", Toast.LENGTH_SHORT).show();
    }

    // ConnectChecker events
    @Override public void onConnectionStarted(String s) {}
    @Override public void onConnectionSuccess() {}
    @Override public void onConnectionFailed(@NonNull String s) {
        Log.e("error",s);
    }
    @Override public void onNewBitrate(long bitrate) {
        bitrateAdapter.adaptBitrate(bitrate, genericStream.getStreamClient().hasCongestion());
    }
    @Override public void onDisconnect() {}
    @Override public void onAuthError() {}
    @Override public void onAuthSuccess() {}

    @NonNull
    @Override
    public View getView() {
        return this; // This FrameLayout that holds SurfaceView
    }

    @Override
    public void dispose() {
        genericStream.release(); // Clean up stream resources
    }
}
