using GLFW
using ModernGL

function main()
    # Windowを作成
    window = GLFW.CreateWindow(640, 480, "GLFW.jl")
    # Windowのcontextを作成
    GLFW.MakeContextCurrent(window)
    iteration::Int = 0
    # Windowが閉じるまでループ
    while !GLFW.WindowShouldClose(window)
        # 画面をクリア
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        # 色を塗り替える
        glClearColor(iteration/1000, 0.0, 0.5, 1)
        # バッファを入れ替える
        GLFW.SwapBuffers(window)
        # 描画
        GLFW.PollEvents()
        
        iteration += 1
        iteration = mod(iteration, 1000)
    end
    # Windowのコンテキストを破棄
    GLFW.DestroyWindow(window)
end

main()