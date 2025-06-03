import tensorflow as tf

try:
    interpreter = tf.lite.Interpreter(model_path="aqi_model.tflite")
    print("✅ Model is valid!")
    print("Input details:", interpreter.get_input_details())
    print("Output details:", interpreter.get_output_details())
except Exception as e:
    print("❌ Invalid model:", e)