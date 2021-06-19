import * as React from 'react';
import { StyleSheet, View, Text, Button, Image } from 'react-native';
import PhotoPicker from '../../src';
import type { ImageAsset } from 'src/types';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();
  const [uri, setUri] = React.useState('');

  React.useEffect(() => {
    setResult(10);
  }, []);

  return (
    <View style={styles.container}>
      <Text>Result: {result}</Text>
      <Image
        style={{ width: 200, height: 200, backgroundColor: 'red' }}
        source={{ uri }}
      />
      <Button
        title="Photo"
        onPress={() => {
          PhotoPicker.openGallery({
            mediaType: 'photo',
            selectionLimit: 1,
          })
            .then((res: ImageAsset[]) => {
              res.forEach((item) => {
                setUri(item.imagePath ?? '');
              });
            })
            .catch((error) => {
              console.log('error = ', error);
            });
        }}
      />
      <Button
        title="Camera"
        onPress={() => {
          PhotoPicker.openCamera({ mediaType: 'video' })
            .then((res: ImageAsset[]) => {
              res.forEach((item) => {
                console.warn('item = ', item.imagePath);
                setUri(item.imagePath ?? '');
              });
            })
            .catch((error) => {
              console.log('error = ', error);
            });
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
