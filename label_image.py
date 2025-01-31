import cv2
import tkinter as tk
from tkinter import filedialog

# Global variable to store landmark coordinates
landmarks = []

def open_image():
    file_path = filedialog.askopenfilename(filetypes=[("Image files", "*.jpg *.png *.jpeg *.bmp *.gif")])
    if file_path:
        img = cv2.imread(file_path)
        cv2.imshow("X-Ray Image", img)
        cv2.setMouseCallback("X-Ray Image", get_mouse_click)

def get_mouse_click(event, x, y, flags, param):
    if event == cv2.EVENT_LBUTTONDOWN:
        landmarks.append((x, y))
        print(f"Landmark added: ({x}, {y})")

def save_landmarks():
    if landmarks:
        with open("landmarks.txt", "w") as f:
            for landmark in landmarks:
                f.write(f"{landmark[0]}, {landmark[1]}\n")
        print("Landmarks saved to 'landmarks.txt'")
    else:
        print("No landmarks to save.")

# Create a simple Tkinter GUI
root = tk.Tk()
root.title("X-Ray Landmark Picker")

open_button = tk.Button(root, text="Open Image", command=open_image)
save_button = tk.Button(root, text="Save Landmarks", command=save_landmarks)

open_button.pack()
save_button.pack()

root.mainloop()

cv2.destroyAllWindows()
