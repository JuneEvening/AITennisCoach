import mediapipe as mp
import cv2
import numpy as np
import os

mp_pose = mp.solutions.pose
pose = mp_pose.Pose(static_image_mode=True, model_complexity=2)

mp_drawing = mp.solutions.drawing_utils

def calculate_angle_3d(a, b, c):
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    ba = a - b
    bc = c - b
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    angle = np.arccos(np.clip(cosine_angle, -1.0, 1.0))
    return np.degrees(angle)

def extract_landmarks(image_path, output_path):
    image = cv2.imread(image_path)
    results = pose.process(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    if not results.pose_landmarks:
        return None, None
    mp_drawing.draw_landmarks(image, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
    cv2.imwrite(output_path, image)
    landmarks = [(l.x, l.y, l.z) for l in results.pose_world_landmarks.landmark]
    return image, landmarks

def compare_pose_angles_3d(coach_path, student_path):
    os.makedirs("frames_pose", exist_ok=True)
    coach_out = "frames_pose/coach_pose.jpg"
    student_out = "frames_pose/student_pose.jpg"
    
    _, coach = extract_landmarks(coach_path, coach_out)
    _, student = extract_landmarks(student_path, student_out)
    
    if coach is None or student is None:
        return {
            "match": False,
            "message": "Pose not detected in one or both frames."
        }
    
    joint_triplets = {
        "Right Elbow": [12, 14, 16],
        "Left Elbow": [11, 13, 15],
        "Right Knee": [24, 26, 28],
        "Left Knee": [23, 25, 27],
        "Right Shoulder": [14, 12, 24],
        "Left Shoulder": [13, 11, 23]
    }
    
    angle_diffs = {}
    for name, (a, b, c) in joint_triplets.items():
        angle_coach = calculate_angle_3d(coach[a], coach[b], coach[c])
        angle_student = calculate_angle_3d(student[a], student[b], student[c])
        angle_diffs[name] = abs(angle_coach - angle_student)
    
    return {
        "match": True,
        "angle_diffs": angle_diffs,
        "coach_annotated": coach_out,
        "student_annotated": student_out,
        "message": "Pose angle comparison complete."
    }
