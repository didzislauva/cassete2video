__author__ = 'didzis'
import os
import subprocess
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel, QFileDialog, QLineEdit, QProgressBar

class ResizeTab(QWidget):
    def __init__(self):
        super().__init__()

        self.selected_file = None
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()

        self.file_label = QLabel("Select Video File:")
        layout.addWidget(self.file_label)

        self.select_btn = QPushButton("Browse")
        self.select_btn.clicked.connect(self.select_file)
        layout.addWidget(self.select_btn)

        self.resize_label = QLabel("Enter Resolution (WidthxHeight):")
        layout.addWidget(self.resize_label)

        self.resize_input = QLineEdit()
        self.resize_input.setPlaceholderText("Example: 1280x720")
        layout.addWidget(self.resize_input)

        self.resize_btn = QPushButton("Resize Video")
        self.resize_btn.clicked.connect(self.run_ffmpeg_resize)
        layout.addWidget(self.resize_btn)

        self.progress = QProgressBar()
        layout.addWidget(self.progress)

        self.status = QLabel("")
        layout.addWidget(self.status)

        self.setLayout(layout)

    def select_file(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "Select Video File", "", "Video Files (*.mp4 *.avi *.mkv *.*)")
        if file_path:
            self.selected_file = file_path
            self.file_label.setText(f"File: {os.path.basename(file_path)}")

    def run_ffmpeg_resize(self):
        if not self.selected_file or not self.resize_input.text():
            self.status.setText("Please select a file and enter a resolution.")
            return
