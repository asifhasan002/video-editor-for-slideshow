//
//  ContentView.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import SwiftUI
import PhotosUI
import AVKit
import AVFoundation

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedVideoURL: URL?
    @State private var isLoading = false
    @State private var currentTempFileURL: URL?

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                    VStack {
                        ProgressView()
                        Text("Loading video...")
                            .foregroundColor(.gray)
                    }
                }
            } else if let videoURL = selectedVideoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
                    .cornerRadius(12)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                    VStack {
                        Image(systemName: "video.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No video selected")
                            .foregroundColor(.gray)
                    }
                }
            }

            PhotosPicker(selection: $selectedItem, matching: .videos) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Select Video")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .onDisappear {
            // Clean up temporary file when view disappears
            if let tempURL = currentTempFileURL {
                try? FileManager.default.removeItem(at: tempURL)
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                // Clean up previous temporary file
                if let tempURL = currentTempFileURL {
                    try? FileManager.default.removeItem(at: tempURL)
                    currentTempFileURL = nil
                }

                if let item = newValue {
                    isLoading = true
                    do {
                        // Try to load as URL first (for files directly selected)
                        if let url = try await item.loadTransferable(type: URL.self) {
                            selectedVideoURL = url
                            currentTempFileURL = nil
                        } else {
                            // For photos library videos, load as Data and save to temp file
                            if let videoData = try await item.loadTransferable(type: Data.self) {
                                // Create a temporary file URL with appropriate extension
                                let tempDirectory = FileManager.default.temporaryDirectory
                                let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".mp4")

                                // Write the video data to the temporary file
                                try videoData.write(to: tempFileURL)
                                selectedVideoURL = tempFileURL
                                currentTempFileURL = tempFileURL
                            }
                        }
                    } catch {
                        print("Error loading video: \(error)")
                        selectedVideoURL = nil
                        currentTempFileURL = nil
                    }
                    isLoading = false
                } else {
                    selectedVideoURL = nil
                    isLoading = false
                    currentTempFileURL = nil
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
