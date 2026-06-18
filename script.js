document.addEventListener('DOMContentLoaded', function() {
    const chatMessages = document.getElementById('chatMessages');
    const userInput = document.getElementById('userInput');
    const sendButton = document.getElementById('sendButton');
    
    // AI朋友的回复库
    const responses = {
        greetings: [
            "你好呀！很高兴见到你！",
            "嗨！今天过得怎么样？",
            "欢迎回来！我很想你！",
            "你好！今天有什么有趣的事情想分享吗？"
        ],
        questions: [
            "这是个好问题！让我想想...",
            "嗯，这个问题很有意思！",
            "我觉得你可以这样想...",
            "这是个值得思考的问题！"
        ],
        compliments: [
            "谢谢你！你真好！",
            "你让我很开心！",
            "和你聊天真的很愉快！",
            "你真是个好朋友！"
        ],
        jokes: [
            "为什么程序员总是分不清万圣节和圣诞节？因为 Oct 31 == Dec 25！",
            "什么动物最懒？当然是树懒！它们连笑都很慢：呵呵...呵...",
            "为什么数学书很悲伤？因为它有太多问题了！",
            "什么电脑最会唱歌？戴尔(Dell)！"
        ],
        default: [
            "继续说，我在听！",
            "这很有趣！",
            "我明白了，然后呢？",
            "嗯嗯，我在认真听你说！",
            "你说得对！",
            "这是个好观点！",
            "我觉得你说得很对！",
            "继续聊，我很感兴趣！"
        ]
    };
    
    // 分析用户输入并选择合适的回复
    function getResponse(input) {
        const lowerInput = input.toLowerCase();
        
        // 检查问候语
        if (lowerInput.includes('你好') || lowerInput.includes('嗨') || lowerInput.includes('hi') || lowerInput.includes('hello')) {
            return responses.greetings[Math.floor(Math.random() * responses.greetings.length)];
        }
        
        // 检查问题
        if (lowerInput.includes('吗') || lowerInput.includes('什么') || lowerInput.includes('为什么') || lowerInput.includes('怎么')) {
            return responses.questions[Math.floor(Math.random() * responses.questions.length)];
        }
        
        // 检查赞美
        if (lowerInput.includes('谢谢') || lowerInput.includes('好') || lowerInput.includes('棒') || lowerInput.includes('厉害')) {
            return responses.compliments[Math.floor(Math.random() * responses.compliments.length)];
        }
        
        // 检查笑话请求
        if (lowerInput.includes('笑话') || lowerInput.includes('搞笑') || lowerInput.includes('开心')) {
            return responses.jokes[Math.floor(Math.random() * responses.jokes.length)];
        }
        
        // 默认回复
        return responses.default[Math.floor(Math.random() * responses.default.length)];
    }
    
    // 添加消息到聊天
    function addMessage(text, isUser) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${isUser ? 'user' : 'bot'}`;
        
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        
        if (!isUser) {
            const nameSpan = document.createElement('span');
            nameSpan.className = 'bot-name';
            nameSpan.textContent = 'AI朋友';
            contentDiv.appendChild(nameSpan);
        }
        
        const textP = document.createElement('p');
        textP.textContent = text;
        contentDiv.appendChild(textP);
        
        messageDiv.appendChild(contentDiv);
        chatMessages.appendChild(messageDiv);
        
        // 滚动到底部
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }
    
    // 发送消息
    function sendMessage() {
        const text = userInput.value.trim();
        if (text === '') return;
        
        // 添加用户消息
        addMessage(text, true);
        userInput.value = '';
        
        // 模拟AI思考时间
        setTimeout(() => {
            const response = getResponse(text);
            addMessage(response, false);
        }, 1000);
    }
    
    // 事件监听
    sendButton.addEventListener('click', sendMessage);
    
    userInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            sendMessage();
        }
    });
    
    // 输入框获得焦点时的动画效果
    userInput.addEventListener('focus', function() {
        this.style.transform = 'scale(1.02)';
    });
    
    userInput.addEventListener('blur', function() {
        this.style.transform = 'scale(1)';
    });
});