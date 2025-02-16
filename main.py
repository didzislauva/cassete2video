import sys
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QTabWidget
from convert_tab import ConvertTab
from audio_tab import AudioTab
from resize_tab import ResizeTab

class FFmpegGUI(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("FFmpeg GUI - Multi-Tab")
        self.setGeometry(100, 100, 500, 300)

        # Create Tab Widget
        self.tabs = QTabWidget(self)

        # Create each tab as an instance of its class
        self.tab1 = ConvertTab()
        self.tab2 = AudioTab()
        self.tab3 = ResizeTab()

        # Add tabs to widget
        self.tabs.addTab(self.tab1, "Convert Video")
        self.tabs.addTab(self.tab2, "Extract Audio")
        self.tabs.addTab(self.tab3, "Resize Video")

        # Set layout
        layout = QVBoxLayout()
        layout.addWidget(self.tabs)
        self.setLayout(layout)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = FFmpegGUI()
    window.show()
    sys.exit(app.exec())
