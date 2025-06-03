import sqlite3
import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Conv1D, Flatten, Input, Dropout

# ✅ Normalization Parameters
NORM_PARAMS = {
    'AQI': {'min': 0, 'max': 500},
    'Temperature': {'min': 15, 'max': 40},
    'Humidity': {'min': 20, 'max': 100}
}

# ✅ Load & Preprocess Data
def load_and_prepare_data():
    try:
        conn = sqlite3.connect("aqi_history.db")
        df = pd.read_sql_query("SELECT date, AQI, Temperature, Humidity FROM history ORDER BY date ASC", conn)
        conn.close()
        
        if df.empty:
            raise ValueError("❌ Error: The database is empty!")
        
        if len(df) < 5:
            raise ValueError(f"❌ Error: Need at least 5 days of data, got {len(df)}")

        # ✅ Normalize Data (0-1 scaling)
        for col in ['AQI', 'Temperature', 'Humidity']:
            df[col] = (df[col] - NORM_PARAMS[col]['min']) / (NORM_PARAMS[col]['max'] - NORM_PARAMS[col]['min'])
            df[col] = np.clip(df[col], 0, 1)  # Ensure values stay between 0 and 1

        sequence_length = 7  # Input: Last 7 days
        future_steps = 3  # Output: Next 3 days
        X, y = [], []
        
        for i in range(len(df) - future_steps):
            seq_start = max(0, i - sequence_length + 1)
            seq = df[['AQI', 'Temperature', 'Humidity']].iloc[seq_start:i+1].values
            
            # ✅ Pad sequences at the beginning with zeros
            if len(seq) < sequence_length:
                padding = np.zeros((sequence_length - len(seq), 3))
                seq = np.vstack([padding, seq])

            X.append(seq)
            y.append(df['AQI'].iloc[i+1:i+1+future_steps].values)

        X, y = np.array(X, dtype=np.float32), np.array(y, dtype=np.float32)

        print(f"✅ Data Prepared - Input shape: {X.shape}, Output shape: {y.shape}")
        return X, y

    except Exception as e:
        print(f"❌ Error loading data: {str(e)}")
        raise

# ✅ Build Improved Model
def build_model(input_shape):
    model = Sequential([
        Input(shape=input_shape),
        Conv1D(32, kernel_size=3, activation="relu"),
        Conv1D(64, kernel_size=3, activation="relu"),
        Flatten(),
        Dense(128, activation="relu"),
        Dropout(0.2),
        Dense(64, activation="relu"),
        Dropout(0.2),
        Dense(3)  # Predict AQI for next 3 days
    ])
    
    model.compile(optimizer='adam', loss='mse', metrics=['mae'])
    model.summary()
    return model

# ✅ Convert to TFLite
def convert_to_tflite(model):
    try:
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        # **Disable aggressive optimization to retain accuracy**
        # converter.optimizations = [tf.lite.Optimize.DEFAULT]  
        tflite_model = converter.convert()
        return tflite_model

    except Exception as e:
        print(f"❌ Error converting to TFLite: {str(e)}")
        raise

# ✅ Main Training & Conversion
def main():
    try:
        X, y = load_and_prepare_data()
        model = build_model((7, 3))
        
        # ✅ Train Model
        history = model.fit(X, y, epochs=100, batch_size=16, validation_split=0.2, verbose=1)
        
        # ✅ Print Training Summary
        print(f"\n✅ Training Complete!")
        print(f"📉 Final Training Loss: {history.history['loss'][-1]:.4f}")
        print(f"📊 Final Validation Loss: {history.history['val_loss'][-1]:.4f}")

        # ✅ Convert to TFLite
        tflite_model = convert_to_tflite(model)
        with open("aqi_model.tflite", "wb") as f:
            f.write(tflite_model)
            
        print("🎯 Model successfully saved as `aqi_model.tflite` ✅")
        
    except Exception as e:
        print(f"❌ Training Failed: {str(e)}")
        raise

if __name__ == "__main__":
    main()
