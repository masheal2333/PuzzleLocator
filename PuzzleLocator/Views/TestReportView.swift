//
//  TestReportView.swift
//  PuzzleLocator
//
//  Created by Sheng Ma on 4/9/25.
//

import SwiftUI

struct TestReportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var reportText: String = ""
    @State private var showingShareSheet = false
    @State private var reportURL: URL? = nil
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    Text(reportText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.systemBackground))
                
                HStack {
                    Button(action: {
                        exportReport()
                    }) {
                        Label("导出报告", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        Label("清除数据", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .alert("确认删除", isPresented: $showingConfirmation) {
                        Button("取消", role: .cancel) { }
                        Button("删除", role: .destructive) {
                            clearTestData()
                        }
                    } message: {
                        Text("确定要删除所有测试数据吗？此操作无法撤销。")
                    }
                }
                .padding()
            }
            .navigationTitle("测试报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("关闭", systemImage: "xmark.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        refreshReport()
                    }) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet, content: {
                if let url = reportURL {
                    ShareSheet(activityItems: [url])
                }
            })
            .onAppear {
                loadReport()
            }
        }
    }
    
    private func loadReport() {
        reportText = TestDataRecorder.shared.generateReport()
    }
    
    private func refreshReport() {
        loadReport()
    }
    
    private func exportReport() {
        reportURL = TestDataRecorder.shared.exportReportToFile()
        if reportURL != nil {
            showingShareSheet = true
        }
    }
    
    private func clearTestData() {
        TestDataRecorder.shared.clearAllTestData()
        loadReport()
    }
}

// ShareSheet 用于分享文件
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct TestReportView_Previews: PreviewProvider {
    static var previews: some View {
        TestReportView()
    }
} 