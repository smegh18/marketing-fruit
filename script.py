with open('pubspec.yaml', 'r') as f:
    text = f.read()

text = text.replace('dev_dependencies:\n  flutter_test:\n    sdk: flutter', 'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n  flutter_launcher_icons: ^0.13.1')

text += '\nflutter_launcher_icons:\n  android: \"launcher_icon\"\n  ios: true\n  image_path: \"assets/logo.png\"\n'

with open('pubspec.yaml', 'w') as f:
    f.write(text)
