export type MediaType = 'photo' | 'video' | 'mixed';

export interface PhotoPickerOptions {
  selectionLimit?: number;
  mediaType?: MediaType;
  editable?: boolean;
}

export interface CameraOptions {
  mediaType?: MediaType;
  editable?: boolean;
}

export interface ImageAsset {
  imagePath?: string;
  imageName?: string;
  width?: number;
  height?: number;
  mimeType?: string;
}
