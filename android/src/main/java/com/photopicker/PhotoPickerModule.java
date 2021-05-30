package com.photopicker;

import android.graphics.Color;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.luck.picture.lib.PictureSelectionModel;
import com.luck.picture.lib.PictureSelector;
import com.luck.picture.lib.config.PictureConfig;
import com.luck.picture.lib.entity.LocalMedia;
import com.luck.picture.lib.listener.OnResultCallbackListener;
import com.luck.picture.lib.style.PictureWindowAnimationStyle;

import java.util.Arrays;
import java.util.List;

public class PhotoPickerModule extends ReactContextBaseJavaModule {

  public final static List<String> mediaTypes = Arrays.asList("mixed", "photo", "video");

  public PhotoPickerModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  @NonNull
  public String getName() {
    return "PhotoPicker";
  }

  @ReactMethod
  public void openGallery(final ReadableMap options, Promise promise) {
    String mediaType = options.hasKey("mediaType") ? options.getString("mediaType") : "mixed";
    int selectionLimit = options.hasKey("selectionLimit") ? options.getInt("selectionLimit") : 1;
    boolean editable = !options.hasKey("editable") || options.getBoolean("editable");

    PictureSelectionModel model = PictureSelector.create(getCurrentActivity())
      .openGallery(mediaTypes.indexOf(mediaType));
    model.isEnableCrop(editable);
    model.selectionMode(selectionLimit > 1 ? PictureConfig.MULTIPLE : PictureConfig.SINGLE);
    model.maxSelectNum(selectionLimit);
    openPictureSelector(model, promise);
  }

  @ReactMethod
  public void openCamera(final ReadableMap options, Promise promise) {
    String mediaType = options.hasKey("mediaType") ? options.getString("mediaType") : "mixed";
    boolean editable = !options.hasKey("editable") || options.getBoolean("editable");

    PictureSelectionModel model = PictureSelector.create(getCurrentActivity())
      .openCamera(mediaTypes.indexOf(mediaType));
    model.selectionMode(PictureConfig.SINGLE);
    model.isEnableCrop(editable);
    openPictureSelector(model, promise);
  }

  private void openPictureSelector(PictureSelectionModel model, Promise promise) {
    PictureWindowAnimationStyle windowAnimationStyle = new PictureWindowAnimationStyle();
    windowAnimationStyle.ofAllAnimation(R.anim.photo_picker_in_activity, R.anim.photo_picker_out_activity);

    model.imageEngine(GlideEngine.createGlideEngine())
      .setPictureWindowAnimationStyle(windowAnimationStyle)
      .isCamera(false)
      .isZoomAnim(false)
      .isPreviewEggs(true)
      .freeStyleCropEnabled(true)
      .rotateEnabled(false)
      .isOriginalImageControl(true)
      .setCropDimmedColor(Color.argb(200, 0, 0, 0))
      .showCropGrid(true)
      .isDragFrame(true)
      .isAutomaticTitleRecyclerTop(true)
      .forResult(new OnResultCallbackListener<LocalMedia>() {
        @Override
        public void onResult(List<LocalMedia> result) {
          WritableArray images = Arguments.createArray();
          for (int i = 0; i < result.size(); i++) {
            LocalMedia item = result.get(i);
            WritableMap map = Arguments.createMap();
            map.putString("imagePath", "file://" + (item.isCut() ? item.getCutPath() : item.getRealPath()));
            map.putString("imageName", item.getFileName());
            map.putString("mimeType", item.getMimeType());
            map.putInt("width", item.getWidth());
            map.putInt("height", item.getHeight());
            images.pushMap(map);
          }
          promise.resolve(images);
        }

        @Override
        public void onCancel() {
          promise.reject("0", "cancel");
        }
      });
  }
}
