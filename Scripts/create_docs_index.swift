#!/usr/bin/env swift

import Foundation

let indexHTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GeminiKit - Swift SDK for Google Gemini AI</title>
    <meta name="description" content="A comprehensive Swift SDK for Google's Gemini AI models with native async/await support, streaming capabilities, and cross-platform compatibility.">
    <meta property="og:title" content="GeminiKit - Swift SDK for Google Gemini AI">
    <meta property="og:description" content="Build AI-powered Swift apps with GeminiKit. Native support for all Apple platforms and Linux.">
    <meta property="og:image" content="https://raw.githubusercontent.com/marcusziade/GeminiKit/main/assets/social-preview.png">
    <meta property="og:url" content="https://marcusziade.github.io/GeminiKit/">
    <meta name="twitter:card" content="summary_large_image">
    <link rel="icon" type="image/png" href="favicon.png">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #1d1d1f;
            background: #000;
            overflow-x: hidden;
        }
        
        .hero {
            min-height: 50vh;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            background: linear-gradient(135deg, #4285f4 0%, #34a853 25%, #fbbc04 50%, #ea4335 75%, #4285f4 100%);
            background-size: 400% 400%;
            animation: gradientShift 20s ease infinite;
            margin-bottom: -40px;
        }
        
        .scroll-indicator {
            position: absolute;
            bottom: 40px;
            left: 50%;
            transform: translateX(-50%);
            animation: bounce 2s infinite;
        }
        
        .scroll-indicator::before {
            content: '↓';
            font-size: 24px;
            color: rgba(255, 255, 255, 0.8);
        }
        
        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% {
                transform: translateX(-50%) translateY(0);
            }
            40% {
                transform: translateX(-50%) translateY(-10px);
            }
            60% {
                transform: translateX(-50%) translateY(-5px);
            }
        }
        
        @keyframes gradientShift {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px;
            position: relative;
            z-index: 1;
        }
        
        .hero-content {
            text-align: center;
            color: white;
        }
        
        .logo {
            width: 80px;
            height: 80px;
            margin: 0 auto 20px;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 40px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        
        h1 {
            font-size: clamp(36px, 6vw, 56px);
            font-weight: 700;
            margin-bottom: 16px;
            letter-spacing: -0.02em;
            text-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }
        
        .subtitle {
            font-size: clamp(18px, 2.5vw, 22px);
            font-weight: 400;
            margin-bottom: 32px;
            opacity: 0.95;
            max-width: 600px;
            margin-left: auto;
            margin-right: auto;
        }
        
        .buttons {
            display: flex;
            gap: 16px;
            justify-content: center;
            flex-wrap: wrap;
        }
        
        .button {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 16px 32px;
            font-size: 18px;
            font-weight: 600;
            text-decoration: none;
            border-radius: 12px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
            position: relative;
        }
        
        .button-primary {
            background: white;
            color: #4285f4;
        }
        
        .button-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
        }
        
        .button-secondary {
            background: rgba(255, 255, 255, 0.2);
            color: white;
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255, 255, 255, 0.3);
            flex-direction: column;
            gap: 4px;
        }
        
        .button-secondary .coming-soon {
            font-size: 12px;
            opacity: 0.8;
            font-weight: 400;
        }
        
        .button-secondary:hover {
            background: rgba(255, 255, 255, 0.3);
            border-color: rgba(255, 255, 255, 0.5);
        }
        
        .features {
            padding: 80px 0;
            background: #f8f9fa;
            position: relative;
            z-index: 10;
            box-shadow: 0 -10px 40px rgba(0, 0, 0, 0.1);
        }
        
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 16px;
            margin-top: 48px;
        }
        
        .feature-card {
            background: white;
            padding: 24px;
            border-radius: 16px;
            border: 1px solid #e0e0e0;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .feature-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, #4285f4, #34a853, #fbbc04, #ea4335);
            transform: scaleX(0);
            transition: transform 0.3s ease;
        }
        
        .feature-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 12px 24px rgba(0, 0, 0, 0.1);
            border-color: #4285f4;
        }
        
        .feature-card:hover::before {
            transform: scaleX(1);
        }
        
        .feature-card:hover .feature-icon {
            transform: scale(1.1) rotate(5deg);
        }
        
        .feature-icon {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, #4285f4, #34a853);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            margin-bottom: 16px;
            transition: transform 0.3s ease;
        }
        
        .feature-title {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 8px;
            color: #1d1d1f;
        }
        
        .feature-description {
            color: #5f6368;
            line-height: 1.4;
            font-size: 14px;
        }
        
        .section-title {
            font-size: clamp(36px, 5vw, 48px);
            font-weight: 700;
            text-align: center;
            margin-bottom: 24px;
            color: #1d1d1f;
        }
        
        .section-subtitle {
            font-size: 20px;
            text-align: center;
            color: #86868b;
            max-width: 600px;
            margin: 0 auto;
        }
        
        .platforms {
            padding: 80px 0;
            background: white;
        }
        
        .platform-icons {
            display: flex;
            justify-content: center;
            gap: 40px;
            flex-wrap: wrap;
            margin-top: 48px;
        }
        
        .platform-icon {
            width: 80px;
            height: 80px;
            background: #f5f5f7;
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 40px;
            transition: all 0.3s ease;
        }
        
        .platform-icon:hover {
            background: linear-gradient(135deg, #4285f4, #34a853);
            transform: scale(1.1);
        }
        
        @media (max-width: 768px) {
            .buttons {
                flex-direction: column;
                align-items: center;
            }
            
            .button {
                width: 100%;
                max-width: 280px;
                justify-content: center;
            }
        }
        
        .gradient-text {
            background: linear-gradient(135deg, #4285f4, #34a853);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .code-examples {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 64px 0;
        }
        
        .code-example {
            background: #1d1d1f;
            color: #f5f5f7;
            padding: 24px;
            border-radius: 16px;
            overflow-x: auto;
            font-family: 'SF Mono', Consolas, monospace;
            font-size: 13px;
            line-height: 1.5;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        
        @media (min-width: 1200px) {
            .code-examples {
                grid-template-columns: repeat(3, 1fr);
            }
        }
        
        .keyword { color: #fc5fa3; }
        .string { color: #fc6a5d; }
        .type { color: #5dd8ff; }
        .function { color: #a167e6; }
        .comment { color: #6c7986; }
    </style>
</head>
<body>
    <section class="hero">
        <div class="container">
            <div class="hero-content">
                <div class="logo">✨</div>
                <h1>GeminiKit</h1>
                <p class="subtitle">
                    A comprehensive Swift SDK for Google's Gemini AI models with native async/await support
                </p>
                <div class="buttons">
                    <a href="documentation/geminikit/" class="button button-primary">
                        <span>📖</span>
                        View Documentation
                    </a>
                    <a href="#" class="button button-secondary">
                        <span style="display: flex; align-items: center; gap: 8px;">
                            <span>🎓</span>
                            <span>Tutorials</span>
                        </span>
                        <span class="coming-soon">Coming Soon</span>
                    </a>
                </div>
            </div>
            <div class="scroll-indicator"></div>
        </div>
    </section>
    
    <section class="features">
        <div class="container">
            <h2 class="section-title">Build <span class="gradient-text">Intelligent Apps</span></h2>
            <p class="section-subtitle">Everything you need to integrate Google's Gemini AI into your Swift applications</p>
            
            <div class="features-grid">
                <div class="feature-card">
                    <div class="feature-icon">🎨</div>
                    <h3 class="feature-title">Image Generation</h3>
                    <p class="feature-description">
                        Imagen 3.0 with multiple aspect ratios and batch support
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🎬</div>
                    <h3 class="feature-title">Video Generation</h3>
                    <p class="feature-description">
                        Veo 2.0 text-to-video and image-to-video creation
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🗣️</div>
                    <h3 class="feature-title">Text-to-Speech</h3>
                    <p class="feature-description">
                        Natural voices with multi-speaker dialogue support
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🧠</div>
                    <h3 class="feature-title">Thinking Mode</h3>
                    <p class="feature-description">
                        Step-by-step reasoning with transparent thought process
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🌐</div>
                    <h3 class="feature-title">Web Grounding</h3>
                    <p class="feature-description">
                        Real-time Google Search for current information
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">💻</div>
                    <h3 class="feature-title">Code Execution</h3>
                    <p class="feature-description">
                        Generate and run code for computational tasks
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🛠️</div>
                    <h3 class="feature-title">Function Calling</h3>
                    <p class="feature-description">
                        Build AI agents with parallel function execution
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🎥</div>
                    <h3 class="feature-title">Multimodal</h3>
                    <p class="feature-description">
                        Process images, videos, audio, and documents
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">⚡</div>
                    <h3 class="feature-title">Streaming</h3>
                    <p class="feature-description">
                        Real-time SSE responses with platform optimization
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🔤</div>
                    <h3 class="feature-title">Embeddings</h3>
                    <p class="feature-description">
                        High-quality vectors for search and similarity
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🔄</div>
                    <h3 class="feature-title">OpenAI Compatible</h3>
                    <p class="feature-description">
                        Drop-in replacement for existing OpenAI code
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🖥️</div>
                    <h3 class="feature-title">CLI Tools</h3>
                    <p class="feature-description">
                        Command-line interface for all features
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">💬</div>
                    <h3 class="feature-title">Chat Sessions</h3>
                    <p class="feature-description">
                        Stateful conversations with history management
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">📊</div>
                    <h3 class="feature-title">Structured Output</h3>
                    <p class="feature-description">
                        JSON mode and schema-enforced responses
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🔒</div>
                    <h3 class="feature-title">Type Safety</h3>
                    <p class="feature-description">
                        Strongly typed Swift API with full autocomplete
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">📁</div>
                    <h3 class="feature-title">File Management</h3>
                    <p class="feature-description">
                        Upload and manage files for processing
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">🛡️</div>
                    <h3 class="feature-title">Safety Controls</h3>
                    <p class="feature-description">
                        Configurable content filtering and harm categories
                    </p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">📦</div>
                    <h3 class="feature-title">Zero Dependencies</h3>
                    <p class="feature-description">
                        Pure Swift with no external packages
                    </p>
                </div>
            </div>
            
            <div class="code-examples">
                <div class="code-example">
                    <span class="comment">// Initialize GeminiKit</span><br>
                    <span class="keyword">import</span> <span class="type">GeminiKit</span><br><br>
                    <span class="keyword">let</span> gemini = <span class="type">GeminiKit</span>(<br>
                    &nbsp;&nbsp;apiKey: <span class="string">"your-api-key"</span><br>
                    )
                </div>
                
                <div class="code-example">
                    <span class="comment">// Text Generation</span><br>
                    <span class="keyword">let</span> response = <span class="keyword">try await</span> gemini.<span class="function">generateContent</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_flash</span>,<br>
                    &nbsp;&nbsp;prompt: <span class="string">"Explain quantum computing"</span><br>
                    )<br>
                    <span class="function">print</span>(response.text ?? <span class="string">""</span>)
                </div>
                
                <div class="code-example">
                    <span class="comment">// Streaming Responses</span><br>
                    <span class="keyword">for try await</span> chunk <span class="keyword">in</span> gemini.<span class="function">streamContent</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_pro</span>,<br>
                    &nbsp;&nbsp;prompt: <span class="string">"Write a story"</span><br>
                    ) {<br>
                    &nbsp;&nbsp;<span class="function">print</span>(chunk.text ?? <span class="string">""</span>)<br>
                    }
                </div>
                
                <div class="code-example">
                    <span class="comment">// Image Generation</span><br>
                    <span class="keyword">let</span> images = <span class="keyword">try await</span> gemini.<span class="function">generateImages</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">imagen_3_0_generate</span>,<br>
                    &nbsp;&nbsp;prompt: <span class="string">"Japanese garden sunset"</span>,<br>
                    &nbsp;&nbsp;aspectRatio: .<span class="function">landscape_16_9</span><br>
                    )
                </div>
                
                <div class="code-example">
                    <span class="comment">// Multimodal Analysis</span><br>
                    <span class="keyword">let</span> result = <span class="keyword">try await</span> gemini.<span class="function">generateContent</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_flash</span>,<br>
                    &nbsp;&nbsp;messages: [<br>
                    &nbsp;&nbsp;&nbsp;&nbsp;.<span class="function">user</span>(<span class="string">"What's in this image?"</span>,<br>
                    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.<span class="function">imageData</span>(imageData))<br>
                    &nbsp;&nbsp;]<br>
                    )
                </div>
                
                <div class="code-example">
                    <span class="comment">// Chat Sessions</span><br>
                    <span class="keyword">let</span> chat = gemini.<span class="function">startChat</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_flash</span><br>
                    )<br>
                    <span class="keyword">let</span> msg = <span class="keyword">try await</span> chat.<span class="function">sendMessage</span>(<br>
                    &nbsp;&nbsp;<span class="string">"Hello! How are you?"</span><br>
                    )
                </div>
                
                <div class="code-example">
                    <span class="comment">// Function Calling</span><br>
                    <span class="keyword">let</span> result = <span class="keyword">try await</span> gemini.<span class="function">generateContent</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_flash</span>,<br>
                    &nbsp;&nbsp;prompt: <span class="string">"Get the weather"</span>,<br>
                    &nbsp;&nbsp;tools: [weatherTool],<br>
                    &nbsp;&nbsp;toolConfig: .<span class="function">auto</span><br>
                    )
                </div>
                
                <div class="code-example">
                    <span class="comment">// Thinking Mode</span><br>
                    <span class="keyword">let</span> stream = gemini.<span class="function">streamContent</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_flash_thinking</span>,<br>
                    &nbsp;&nbsp;prompt: <span class="string">"Design a system"</span><br>
                    )<br>
                    <span class="comment">// Shows reasoning steps</span>
                </div>
                
                <div class="code-example">
                    <span class="comment">// Text-to-Speech</span><br>
                    <span class="keyword">let</span> audio = <span class="keyword">try await</span> gemini.<span class="function">generateSpeech</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_flash_tts</span>,<br>
                    &nbsp;&nbsp;text: <span class="string">"Hello world!"</span>,<br>
                    &nbsp;&nbsp;voice: .<span class="function">aoede</span><br>
                    )
                </div>
                
                <div class="code-example">
                    <span class="comment">// Embeddings</span><br>
                    <span class="keyword">let</span> embedding = <span class="keyword">try await</span> gemini.<span class="function">embedContent</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">textEmbedding004</span>,<br>
                    &nbsp;&nbsp;content: <span class="string">"Semantic search text"</span><br>
                    )<br>
                    <span class="comment">// Returns vector array</span>
                </div>
                
                <div class="code-example">
                    <span class="comment">// Web Grounding</span><br>
                    <span class="keyword">let</span> result = <span class="keyword">try await</span> gemini.<span class="function">generateContent</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_flash</span>,<br>
                    &nbsp;&nbsp;prompt: <span class="string">"Latest AI news"</span>,<br>
                    &nbsp;&nbsp;tools: [.<span class="function">googleSearch</span>()]<br>
                    )
                </div>
                
                <div class="code-example">
                    <span class="comment">// Code Execution</span><br>
                    <span class="keyword">let</span> result = <span class="keyword">try await</span> gemini.<span class="function">generateContent</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_flash</span>,<br>
                    &nbsp;&nbsp;prompt: <span class="string">"Calculate fibonacci"</span>,<br>
                    &nbsp;&nbsp;tools: [.<span class="function">codeExecution</span>()]<br>
                    )
                </div>
                
                <div class="code-example">
                    <span class="comment">// JSON Mode</span><br>
                    <span class="keyword">let</span> result = <span class="keyword">try await</span> gemini.<span class="function">generateContent</span>(<br>
                    &nbsp;&nbsp;model: .<span class="function">gemini_2_5_flash</span>,<br>
                    &nbsp;&nbsp;prompt: <span class="string">"List 3 colors"</span>,<br>
                    &nbsp;&nbsp;generationConfig: .<span class="function">init</span>(<br>
                    &nbsp;&nbsp;&nbsp;&nbsp;responseMIMEType: <span class="string">"application/json"</span><br>
                    &nbsp;&nbsp;)<br>
                    )
                </div>
            </div>
        </div>
    </section>
    
    <section class="platforms">
        <div class="container">
            <h2 class="section-title">Multi-Platform Support</h2>
            <p class="section-subtitle">Build once, deploy everywhere</p>
            
            <div class="platform-icons">
                <div class="platform-icon">📱</div>
                <div class="platform-icon">💻</div>
                <div class="platform-icon">📺</div>
                <div class="platform-icon">⌚</div>
                <div class="platform-icon">🥽</div>
                <div class="platform-icon">🐧</div>
            </div>
        </div>
    </section>
    
    <script>
        // Add smooth scroll behavior
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth'
                    });
                }
            });
        });
    </script>
</body>
</html>
"""

// Write the index.html file
let fileURL = URL(fileURLWithPath: "docs/index.html")
try indexHTML.write(to: fileURL, atomically: true, encoding: .utf8)
print("✅ Created docs/index.html successfully!")