import { NativeModules } from 'react-native';
import type { CameraOptions, ImageAsset, PhotoPickerOptions } from './types';

type PhotoPickerType = {
  openGallery(options: PhotoPickerOptions): Promise<ImageAsset[]>;
  openCamera(options: CameraOptions): Promise<ImageAsset[]>;
};

const { PhotoPicker } = NativeModules;

export default PhotoPicker as PhotoPickerType;
