## load libraries
library(shiny)
library(reticulate)
options(shiny.maxRequestSize = 100 * 1024^2)

## user interface code
ui <- fluidPage(
  titlePanel("🎾 AI Coach"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Professional Video"),
      fileInput("video_file", "Upload Professional's .mp4 video", accept = ".mp4"),
      actionButton("extract_frames", "Extract Professional Frames"),
      actionButton("annotate_frames", "Annotate Professional Frames"),
      uiOutput("frame_selector"),
      
      hr(),
      
      h4("Student Video"),
      fileInput("student_video_file", "Upload Student's .mp4 video", accept = ".mp4"),
      actionButton("extract_student_frames", "Extract Student Frames"),
      actionButton("annotate_student_frames", "Annotate Student Frames"),
      uiOutput("student_frame_selector"),
      
      hr(),
      actionButton("compare_poses", "Compare Poses"),
      actionButton("get_chatgpt_advice", "Get Tennis Coach Advice")
    ),
    
    mainPanel(
      h4("Professional Video & Frame"),
      uiOutput("video_ui"),
      imageOutput("selected_frame"),
      
      h4("Student Video & Frame"),
      uiOutput("student_video_ui"),
      imageOutput("student_selected_frame"),
      
      h4("Pose Comparison (3D Joint Angles)"),
      fluidRow(
        column(6, imageOutput("coach_pose_img")),
        column(6, imageOutput("student_pose_img")),
        column(12, imageOutput("difference_image"))
      ),
      verbatimTextOutput("pose_analysis_text"),
      
      h4("AI Tennis Coaching Advice"),
      textInput("user_input", "Ask GPT:", "Enter your coaching question or use pose comparison."),
      actionButton("submit", "Submit"),
      verbatimTextOutput("gpt_response")
    )
  )
)

source_python("chatgpt_request.py")

## server code
server <- function(input, output, session) {
  values <- reactiveValues(
    video_name = NULL,
    frame_list = NULL,
    student_video_name = NULL,
    student_frame_list = NULL,
    angle_diffs = NULL
  )
  
  observeEvent(input$video_file, {
    req(input$video_file)
    if (!dir.exists("www")) dir.create("www")
    values$video_name <- input$video_file$name
    file.copy(input$video_file$datapath, file.path("www", values$video_name), overwrite = TRUE)
    output$video_ui <- renderUI({
      HTML(paste0("<video width='400' controls><source src='", values$video_name, "' type='video/mp4'></video>"))
    })
  })
  
  observeEvent(input$extract_frames, {
    req(values$video_name)
    if (!dir.exists("frames")) dir.create("frames")
    unlink("frames/*")
    cmd <- sprintf("ffmpeg -y -i %s -vf fps=1 %s",
                   shQuote(file.path("www", values$video_name)),
                   shQuote(file.path("frames", "frame_%03d.jpg")))
    system(cmd)
    values$frame_list <- list.files("frames", pattern = "\\.jpg$", full.names = FALSE)
    updateSelectInput(session, "frame_choice", choices = values$frame_list)
  })
  
  output$frame_selector <- renderUI({
    req(values$frame_list)
    selectInput("frame_choice", "Choose a Coach Frame", choices = values$frame_list)
  })
  
  output$selected_frame <- renderImage({
    req(input$frame_choice)
    list(src = file.path("frames", input$frame_choice), contentType = "image/jpeg", width = 400)
  }, deleteFile = FALSE)
  
  observeEvent(input$annotate_frames, {
    req(values$frame_list)
    source_python("annotate_frames.py")
    annotate_all_frames("frames", "frames_pose")
  })
  
  observeEvent(input$student_video_file, {
    req(input$student_video_file)
    values$student_video_name <- input$student_video_file$name
    file.copy(input$student_video_file$datapath, file.path("www", values$student_video_name), overwrite = TRUE)
    output$student_video_ui <- renderUI({
      HTML(paste0("<video width='400' controls><source src='", values$student_video_name, "' type='video/mp4'></video>"))
    })
  })
  
  observeEvent(input$extract_student_frames, {
    req(values$student_video_name)
    if (!dir.exists("student_frames")) dir.create("student_frames")
    unlink("student_frames/*")
    cmd <- sprintf("ffmpeg -i www/%s -vf fps=1 student_frames/frame_%%03d.jpg", values$student_video_name)
    system(cmd)
    values$student_frame_list <- list.files("student_frames", pattern = "\\.jpg$", full.names = FALSE)
    updateSelectInput(session, "student_frame_choice", choices = values$student_frame_list)
  })
  
  output$student_frame_selector <- renderUI({
    req(values$student_frame_list)
    selectInput("student_frame_choice", "Choose a Student Frame", choices = values$student_frame_list)
  })
  
  output$student_selected_frame <- renderImage({
    req(input$student_frame_choice)
    list(src = file.path("student_frames", input$student_frame_choice), contentType = "image/jpeg", width = 400)
  }, deleteFile = FALSE)
  
  observeEvent(input$annotate_student_frames, {
    req(values$student_frame_list)
    source_python("annotate_frames.py")
    annotate_all_frames("student_frames", "student_frames_pose")
  })
  
  observeEvent(input$compare_poses, {
    req(input$frame_choice, input$student_frame_choice)
    source_python("compare_pose_angles_3d.py")
    
    result <- compare_pose_angles_3d(
      file.path("frames_pose", input$frame_choice),
      file.path("student_frames_pose", input$student_frame_choice)
    )
    
    if (!is.null(result$match) && result$match) {
      values$angle_diffs <- result$angle_diffs
      
      output$coach_pose_img <- renderImage({
        if (file.exists(result$coach_annotated)) {
          list(src = result$coach_annotated, contentType = "image/jpeg", width = 400)
        } else NULL
      }, deleteFile = FALSE)
      
      output$student_pose_img <- renderImage({
        if (file.exists(result$student_annotated)) {
          list(src = result$student_annotated, contentType = "image/jpeg", width = 400)
        } else NULL
      }, deleteFile = FALSE)
      
      output$difference_image <- renderImage({
        if (file.exists(result$difference_image)) {
          list(src = result$difference_image, contentType = "image/jpeg", width = 800)
        } else NULL
      }, deleteFile = FALSE)
      
      output$pose_analysis_text <- renderPrint({
        cat("📏 3D Angle Differences (degrees):\n\n")
        for (joint in names(result$angle_diffs)) {
          diff <- round(result$angle_diffs[[joint]], 2)
          cat(sprintf("%-20s : %5.2f°\n", joint, diff))
        }
      })
    } else {
      output$pose_analysis_text <- renderText({ result$message })
    }
  })
  
  observeEvent(input$get_chatgpt_advice, {
    req(values$angle_diffs)
    
    ## can be replaced by a local python enviroment
    reticulate::use_python("/Users/juneevening/r-mediapipe-env-310/bin/python", required = TRUE)
    reticulate::py_config()
    
    Sys.setenv(OPENAI_API_KEY = Sys.getenv("OPENAI_API_KEY"))
    
    advice_prompt <- paste(
      "Here are 3D joint angle differences between coach and student:",
      paste(
        sapply(names(values$angle_diffs), function(j) {
          sprintf("%s: %.2f degrees", j, values$angle_diffs[[j]])
        }), collapse = "\n"
      ),
      "\n\nGive professional tennis coaching feedback: interpretation, advice, drills to fix mistakes, and injury prevention tips.",
      sep = "\n"
    )
    
    ## catch exceptios when loading query response from
    tryCatch({
      source_python("chatgpt_query.py")
      output_text <- call_gpt_model(advice_prompt)
      output$chatgpt_output <- renderText({ output_text })
    }, error = function(e) {
      output$chatgpt_output <- renderText({ paste("GPT Error:", e$message) })
    })
  })
  
  
  response <- eventReactive(input$submit, {
    tryCatch({
      chatgptquery(input$user_input)
    }, error = function(e) {
      paste("Error:", e$message)
    })
  })
  
  output$gpt_response <- renderText({
    response()
  })
}

## run shinyApp
shinyApp(ui, server)

