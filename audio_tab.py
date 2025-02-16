import os
import subprocess
import json
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel, QFileDialog, QComboBox, QProgressBar

class AudioTab(QWidget):
    def __init__(self):
        super().__init__()

        self.selected_file = None
        self.audio_streams = []  # List of detected audio streams
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()

        self.file_label = QLabel("Select Video File:")
        layout.addWidget(self.file_label)

        self.select_btn = QPushButton("Browse")
        self.select_btn.clicked.connect(self.select_file)
        layout.addWidget(self.select_btn)

        self.stream_label = QLabel("Select Audio Stream:")
        layout.addWidget(self.stream_label)

        self.stream_combo = QComboBox()  # Dropdown for streams
        layout.addWidget(self.stream_combo)

        self.audio_format_label = QLabel("Output Format:")
        layout.addWidget(self.audio_format_label)

        self.audio_format_combo = QComboBox()
        self.audio_format_combo.addItems(["mp3", "aac", "wav"])
        layout.addWidget(self.audio_format_combo)

        self.extract_btn = QPushButton("Extract Audio")
        self.extract_btn.clicked.connect(self.run_ffmpeg_audio_extract)
        layout.addWidget(self.extract_btn)

        self.progress = QProgressBar()
        layout.addWidget(self.progress)

        self.status = QLabel("")
        layout.addWidget(self.status)

        self.setLayout(layout)

    def select_file(self):
        """Opens a file dialog to select a video file and retrieves audio streams."""
        file_path, _ = QFileDialog.getOpenFileName(self, "Select Video File", "", "Video Files (*.mp4 *.avi *.mkv *.*)")
        if file_path:
            self.selected_file = file_path
            self.file_label.setText(f"File: {os.path.basename(file_path)}")
            self.get_audio_streams()

    def get_audio_streams(self):
        """Uses FFmpeg to retrieve available audio streams."""
        self.audio_streams.clear()
        self.stream_combo.clear()

        ffprobe_cmd = f'ffprobe -v error -select_streams a -show_streams -of json "{self.selected_file}"'
        try:
            result = subprocess.run(ffprobe_cmd, shell=True, capture_output=True, text=True, check=True)
            streams_info = json.loads(result.stdout)
            
            if "streams" in streams_info:
                for index, stream in enumerate(streams_info["streams"]):
                    codec = stream.get("codec_name", "unknown")
                    language = stream.get("tags", {}).get("language", "unknown")
                    description = f"Stream {index} - {codec} ({language})"
                    self.audio_streams.append(index)
                    self.stream_combo.addItem(description, index)

            if not self.audio_streams:
                self.stream_combo.addItem("No audio streams found")

        except Exception as e:
            self.status.setText(f"Error retrieving streams: {e}")

    def run_ffmpeg_audio_extract(self):
        """Extracts the selected audio stream in the chosen format."""
        if not self.selected_file:
            self.status.setText("Please select a file first.")
            return

        if not self.audio_streams:
            self.status.setText("No audio streams found.")
            return

        selected_index = self.stream_combo.currentIndex()
        stream_number = self.audio_streams[selected_index]
        format = self.audio_format_combo.currentText()
        output_file = os.path.splitext(self.selected_file)[0] + f"_stream{stream_number}." + format
        ffmpeg_cmd = f'ffmpeg -i "{self.selected_file}" -map 0:a:{stream_number} -q:a 0 "{output_file}"'

        self.status.setText(f"Extracting audio (Stream {stream_number})...")
        self.progress.setValue(50)

        process = subprocess.run(ffmpeg_cmd, shell=True)

        if process.returncode == 0:
            self.status.setText("Audio extraction complete!")
            self.progress.setValue(100)
        else:
            self.status.setText("Error during extraction.")
            self.progress.setValue(0)
