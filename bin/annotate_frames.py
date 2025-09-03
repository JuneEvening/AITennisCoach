# annotate_frames.py
import mediapipe as mp
import cv2
import os

mp_pose = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils

def annotate_all_frames(input_dir, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    pose = mp_pose.Pose(static_image_mode=True)

    for file_name in os.listdir(input_dir):
        if file_name.endswith('.jpg'):
            input_path = os.path.join(input_dir, file_name)
            output_path = os.path.join(output_dir, file_name)

            image = cv2.imread(input_path)
            results = pose.process(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))

            if results.pose_landmarks:
                mp_drawing.draw_landmarks(
                    image, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
                cv2.imwrite(output_path, image)
