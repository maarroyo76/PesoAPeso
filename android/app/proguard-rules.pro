# google_mlkit_text_recognition declara los modelos de chino, devanagari,
# japonés y coreano como opcionales (compileOnly). La app solo usa el latino
# (lectura del texto de boletas), así que R8 no debe exigir esas clases.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
