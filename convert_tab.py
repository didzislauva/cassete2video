import os
import subprocess
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel, QFileDialog, QComboBox, QProgressBar

class ConvertTab(QWidget):
    def __init__(self):
        super().__init__()

        self.selected_file = None  # Store the selected file
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()

        self.file_label = QLabel("Select Video File:")
        layout.addWidget(self.file_label)

        self.select_btn = QPushButton("Browse")
        self.select_btn.clicked.connect(self.select_file)
        layout.addWidget(self.select_btn)

        self.format_label = QLabel("Output Format:")
        layout.addWidget(self.format_label)

        self.format_combo = QComboBox()
        self.format_combo.addItems(["mp4", "avi", "mkv"])
        layout.addWidget(self.format_combo)

        self.convert_btn = QPushButton("Convert")
        self.convert_btn.clicked.connect(self.run_ffmpeg_conversion)
        layout.addWidget(self.convert_btn)

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

    def run_ffmpeg_conversion(self):
        if not self.selected_file:
            self.status.setText("Please select a file first.")
            return

        input_file = self.selected_file
        format = self.format_combo.currentText()
        output_file = os.path.splitext(input_file)[0] + "." + format
        ffmpeg_cmd = f'ffmpeg -i "{input_file}" "{output_file}"'

        self.status.setText("Converting...")
        self.progress.setValue(50)

        process = subprocess.run(ffmpeg_cmd, shell=True)

        if process.returncode == 0:
            self.status.setText("Conversion complete!")
            self.progress.setValue(100)
        else:
            self.status.setText("Error during conversion.")
            self.progress.setValue(0)

