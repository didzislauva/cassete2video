import sys
import os
import subprocess
from PyQt6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QPushButton, QLabel, QFileDialog, 
    QComboBox, QTabWidget, QProgressBar, QLineEdit
)

class FFmpegGUI(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("FFmpeg GUI - Multi-Tab")
        self.setGeometry(100, 100, 500, 300)

        # Create a dictionary to track selected files
        self.selected_files = {}

        # Create Tab Widget
        self.tabs = QTabWidget(self)

        # Create each tab
        self.tab1 = self.create_conversion_tab()
        self.tab2 = self.create_audio_extract_tab()
        self.tab3 = self.create_resize_tab()

        # Add tabs to widget
        self.tabs.addTab(self.tab1, "Convert Video")
        self.tabs.addTab(self.tab2, "Extract Audio")
        self.tabs.addTab(self.tab3, "Resize Video")

        # Set layout
        layout = QVBoxLayout()
        layout.addWidget(self.tabs)
        self.setLayout(layout)

    # ---------------------- UNIVERSAL SELECT FILE FUNCTION ----------------------
    def select_file(self, tab_id):
        file_path, _ = QFileDialog.getOpenFileName(self, "Select Video File", "", "Video Files (*.mp4 *.avi *.mkv *.*)")
        if file_path:
            self.selected_files[tab_id] = file_path  # Store the file per tab
            if tab_id == "convert":
                self.file_label1.setText(f"File: {os.path.basename(file_path)}")
            elif tab_id == "audio":
                self.file_label2.setText(f"File: {os.path.basename(file_path)}")
            elif tab_id == "resize":
                self.file_label3.setText(f"File: {os.path.basename(file_path)}")

    # ---------------------- TAB 1: Convert Video ----------------------
    def create_conversion_tab(self):
        tab = QWidget()
        layout = QVBoxLayout()

        self.file_label1 = QLabel("Select Video File:")
        layout.addWidget(self.file_label1)

        self.select_btn1 = QPushButton("Browse")
        self.select_btn1.clicked.connect(lambda: self.select_file("convert"))
        layout.addWidget(self.select_btn1)

        self.format_label = QLabel("Output Format:")
        layout.addWidget(self.format_label)

        self.format_combo = QComboBox()
        self.format_combo.addItems(["mp4", "avi", "mkv"])
        layout.addWidget(self.format_combo)

        self.convert_btn = QPushButton("Convert")
        self.convert_btn.clicked.connect(self.run_ffmpeg_conversion)
        layout.addWidget(self.convert_btn)

        self.progress1 = QProgressBar()
        layout.addWidget(self.progress1)

        self.status1 = QLabel("")
        layout.addWidget(self.status1)

        tab.setLayout(layout)
        return tab

    def run_ffmpeg_conversion(self):
        if "convert" not in self.selected_files:
            self.status1.setText("Please select a file first.")
            return
        
        input_file = self.selected_files["convert"]
        format = self.format_combo.currentText()
        output_file = os.path.splitext(input_file)[0] + "." + format
        ffmpeg_cmd = f'ffmpeg -i "{input_file}" "{output_file}"'

        self.status1.setText("Converting...")
        self.progress1.setValue(50)

        process = subprocess.run(ffmpeg_cmd, shell=True)

        if process.returncode == 0:
            self.status1.setText("Conversion complete!")
            self.progress1.setValue(100)
        else:
            self.status1.setText("Error during conversion.")
            self.progress1.setValue(0)

    # ---------------------- TAB 2: Extract Audio ----------------------
    def create_audio_extract_tab(self):
        tab = QWidget()
        layout = QVBoxLayout()

        self.file_label2 = QLabel("Select Video File:")
        layout.addWidget(self.file_label2)

        self.select_btn2 = QPushButton("Browse")
        self.select_btn2.clicked.connect(lambda: self.select_file("audio"))
        layout.addWidget(self.select_btn2)

        self.audio_format_label = QLabel("Audio Format:")
        layout.addWidget(self.audio_format_label)

        self.audio_format_combo = QComboBox()
        self.audio_format_combo.addItems(["mp3", "aac", "wav"])
        layout.addWidget(self.audio_format_combo)

        self.extract_btn = QPushButton("Extract Audio")
        self.extract_btn.clicked.connect(self.run_ffmpeg_audio_extract)
        layout.addWidget(self.extract_btn)

        self.progress2 = QProgressBar()
        layout.addWidget(self.progress2)

        self.status2 = QLabel("")
        layout.addWidget(self.status2)

        tab.setLayout(layout)
        return tab

    def run_ffmpeg_audio_extract(self):
        if "audio" not in self.selected_files:
            self.status2.setText("Please select a file first.")
            return

        input_file = self.selected_files["audio"]
        format = self.audio_format_combo.currentText()
        output_file = os.path.splitext(input_file)[0] + "." + format
        ffmpeg_cmd = f'ffmpeg -i "{input_file}" -q:a 0 -map a "{output_file}"'

        self.status2.setText("Extracting audio...")
        self.progress2.setValue(50)

        process = subprocess.run(ffmpeg_cmd, shell=True)

        if process.returncode == 0:
            self.status2.setText("Audio extraction complete!")
            self.progress2.setValue(100)
        else:
            self.status2.setText("Error during extraction.")
            self.progress2.setValue(0)

    # ---------------------- TAB 3: Resize Video ----------------------
    def create_resize_tab(self):
        tab = QWidget()
        layout = QVBoxLayout()

        self.file_label3 = QLabel("Select Video File:")
        layout.addWidget(self.file_label3)

        self.select_btn3 = QPushButton("Browse")
        self.select_btn3.clicked.connect(lambda: self.select_file("resize"))
        layout.addWidget(self.select_btn3)

        self.resize_label = QLabel("Enter Resolution (WidthxHeight):")
        layout.addWidget(self.resize_label)

        self.resize_input = QLineEdit()
        self.resize_input.setPlaceholderText("Example: 1280x720")
        layout.addWidget(self.resize_input)

        self.resize_btn = QPushButton("Resize Video")
        self.resize_btn.clicked.connect(self.run_ffmpeg_resize)
        layout.addWidget(self.resize_btn)

        self.progress3 = QProgressBar()
        layout.addWidget(self.progress3)

        self.status3 = QLabel("")
        layout.addWidget(self.status3)

        tab.setLayout(layout)
        return tab

    def run_ffmpeg_resize(self):
        if "resize" not in self.selected_files or not self.resize_input.text():
            self.status3.setText("Please select a file and enter a resolution.")
            return

        input_file = self.selected_files["resize"]
        resolution = self.resize_input.text()
        output_file = os.path.splitext(input_file)[0] + "_resized.mp4"
        ffmpeg_cmd = f'ffmpeg -i "{input_file}" -vf scale={resolution} "{output_file}"'

        self.status3.setText("Resizing...")
        self.progress3.setValue(50)

        process = subprocess.run(ffmpeg_cmd, shell=True)

        if process.returncode == 0:
            self.status3.setText("Resize complete!")
            self.progress3.setValue(100)
        else:
            self.status3.setText("Error resizing video.")
            self.progress3.setValue(0)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = FFmpegGUI()
    window.show()
    sys.exit(app.exec())
