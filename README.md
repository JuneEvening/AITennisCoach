# AI Tennis Coach
An AI-Powered Framework for Objective Tennis Performance Analysis.

# Working Steps 
1. Users upload videos of a pro and a student player.
2. The app extracts frames from the videos.
3. MediaPipe analyses each frame to annotate body landmarks of 33 joints.
4. The app calculates differences in relative joint angles between the pro and student.
5. These differences are sent to OpenAI to generate personalised coaching advice.
6. The coaching advice and any queries typed in, are shown in the web app.

# Setup
1. Isntall R, RStudio, and Python enviroment.
2. Get an OpenAI API key from platform.openai.com/api-keys.
3. Install Python packages: Open terminal and run:
   pip install opencv-python mediapipe openai
4. Install R packages: In RStudio, run:
   install.packages(c("shiny", "reticulate"))
5. Set your API key: In R, run:
   Sys.setenv(OPENAI_API_KEY = 'your-key-here')

# How to Run
Open app.R in RStudio and click "Run App".

# How to Use
1. Open the app in your browser.
2. Upload a pro video (e.g., from YouTube), click "Extract Frames", then "Annotate Frames". Pick a good frame.
3. Do the same with a student video.
4. Click "Compare Poses" to see the analysis.
5. Click "Get Tennis Coach Advice" for AI feedback.

# App Demo
