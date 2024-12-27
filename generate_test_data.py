import numpy as np
from sklearn.datasets import make_blobs
import struct

# Generate synthetic data
def generate_sample_data(n_samples=100, n_features=2):
    X, y = make_blobs(n_samples=n_samples, 
                      n_features=n_features, 
                      centers=2, 
                      cluster_std=1.0,
                      random_state=42)
    
    # Convert labels from 0/1 to -1/1
    y = 2 * y - 1
    
    # Scale features to integer range (0-100) for assembly code
    X = ((X - X.min()) / (X.max() - X.min()) * 100).astype(np.int32)
    
    return X, y

def save_data_for_asm(X, y, feature_file="data/features.bin", label_file="data/labels.bin"):
    # Save features
    with open(feature_file, 'wb') as f:
        # Write number of samples and features as header
        f.write(struct.pack('II', X.shape[0], X.shape[1]))
        # Write feature data
        X.tofile(f)
    
    # Save labels
    with open(label_file, 'wb') as f:
        # Write number of labels as header
        f.write(struct.pack('I', len(y)))
        # Write label data
        y.astype(np.int32).tofile(f)

def visualize_data(X, y):
    import matplotlib.pyplot as plt
    plt.scatter(X[y == -1][:, 0], X[y == -1][:, 1], c='red', label='Class -1')
    plt.scatter(X[y == 1][:, 0], X[y == 1][:, 1], c='blue', label='Class 1')
    plt.legend()
    plt.savefig('data/data_visualization.png')
    plt.close()

if __name__ == "__main__":
    # Generate data
    X, y = generate_sample_data(100, 2)
    
    # Save data for ASM
    save_data_for_asm(X, y)
    
    # Visualize the data
    visualize_data(X, y)
    
    # Print sample for verification
    print("Sample data points:")
    for i in range(5):
        print(f"Features: {X[i]}, Label: {y[i]}")
