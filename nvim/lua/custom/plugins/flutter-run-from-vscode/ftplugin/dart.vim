autocmd BufEnter *.dart command! -buffer -nargs=* FlutterRunVSCode lua require("flutter-run-from-vscode").run_from_vscode()
