package com.horoftech.probashi_live;

import android.app.Activity;
import android.content.Context;
import android.hardware.camera2.CameraCharacteristics;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.Toast;
import com.pedro.encoder.input.video.CameraHelper.Facing;
import com.pedro.encoder.input.sources.audio.AudioSource;
import android.util.DisplayMetrics;
import com.pedro.encoder.input.sources.video.Camera2Source;
import com.pedro.encoder.input.sources.video.VideoSource;
import com.pedro.library.view.OpenGlView;
import androidx.annotation.NonNull;
import com.pedro.encoder.input.gl.render.filters.BlackFilterRender;
import com.pedro.encoder.input.gl.render.filters.BeautyFilterRender;
import com.pedro.encoder.input.sources.audio.MicrophoneSource;
import com.pedro.library.generic.GenericCamera1;
import com.pedro.common.ConnectChecker;
import com.pedro.library.generic.GenericStream;
import com.pedro.library.util.BitrateAdapter;


import io.flutter.plugin.platform.PlatformView;

public class GenericStreamView extends FrameLayout implements PlatformView, ConnectChecker {

//    private final SurfaceView surfaceView;
    private final OpenGlView surfaceView;
    private final GenericStream genericStream;
    private final BitrateAdapter bitrateAdapter;

    final int bitrate = 2200*1000;
    Camera2Source source;
    boolean isCameraOn = true;
    boolean isBeautyEnabled = false;


    Context context;

    public GenericStreamView(@NonNull Context context) {
        super(context);
        this.context = context;
        surfaceView = new OpenGlView(context);
        addView(surfaceView);
        genericStream = new GenericStream(context, this);
        bitrateAdapter = new BitrateAdapter(bitrat -> genericStream.setVideoBitrateOnFly(bitrat));
        bitrateAdapter.setMaxBitrate(bitrate);
        VideoSource videoSource = genericStream.getVideoSource();
        if (videoSource instanceof Camera2Source ) {
            source = (Camera2Source)videoSource;
            source.enableAutoWhiteBalance(CameraCharacteristics.CONTROL_AWB_MODE_DAYLIGHT);
            source.enableAutoExposure();
            if(source.getCameraFacing() == Facing.BACK){
                source.switchCamera();
            }
        }

        surfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                if (genericStream.isOnPreview()) {
                    genericStream.stopPreview();
                }
                genericStream.startPreview(surfaceView);
//                genericStream.getGlInterface().addFilter(new BeautyFilterRender());
            }
            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
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

        Log.e("width",String.valueOf(width));
        Log.e("height",String.valueOf(height));

        boolean prepared =  genericStream.prepareVideo(1280,720,bitrate,30,2,90)
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

    public void toggleBeauty(){
        if(isBeautyEnabled){
            isBeautyEnabled = false;
            genericStream.getGlInterface().removeFilter(0);
        }else {
            isBeautyEnabled = true;
            genericStream.getGlInterface().addFilter(0,new BeautyFilterRender());
        }
    }
    public void startPreview(){
        genericStream.startPreview(surfaceView);
    }
   public void stopPreview(){
       genericStream.stopPreview();
    }

    public void startStream(String url) {
        Toast.makeText(context, "start stream called", Toast.LENGTH_SHORT).show();
        genericStream.startStream(url);
    }


    public void stopStream() {
        genericStream.stopStream();
    }

    public void switchCamera() {
        source.switchCamera();
    }
    public void toggleCamera(){
        if(isCameraOn){
            isCameraOn = false;
            genericStream.getGlInterface().addFilter(0, new BlackFilterRender());
        }else {
            isCameraOn = true;
            genericStream.getGlInterface().removeFilter(0);
        }
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
