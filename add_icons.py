with open('pubspec.yaml', 'a') as f:
    f.write('\nflutter_launcher_icons:\n  android: \
launcher_icon\\n  ios: true\n  image_path: \assets/logo.png\\n')
with open('pubspec.yaml', 'r') as f:
    lines = f.readlines()
with open('pubspec.yaml', 'w') as f:
    for line in lines:
        if line.startswith('dev_dependencies:'):
            f.write(line)
            f.write('  flutter_launcher_icons: ^0.13.1\n')
        else:
            f.write(line)
