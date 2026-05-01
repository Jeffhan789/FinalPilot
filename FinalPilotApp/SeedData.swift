import Foundation

enum SeedData {
    static let courses: [Course] = [
        Course(
            id: "neural_network",
            name: "神经网络",
            examDate: .finalPilotDate(month: 5, day: 13, hour: 9),
            difficulty: 5,
            colorKey: "teal",
            symbol: "point.3.connected.trianglepath.dotted",
            knowledgePoints: [
                KnowledgePoint(id: "nn_perceptron", chapter: "基础模型", title: "感知机", difficulty: 2, mastery: 0.48, status: .inProgress),
                KnowledgePoint(id: "nn_activation", chapter: "基础组件", title: "激活函数", difficulty: 3, mastery: 0.54, status: .inProgress),
                KnowledgePoint(id: "nn_loss", chapter: "训练目标", title: "损失函数", difficulty: 3, mastery: 0.52, status: .inProgress),
                KnowledgePoint(id: "nn_gradient_descent", chapter: "模型训练", title: "梯度下降", difficulty: 4, mastery: 0.36, status: .weak),
                KnowledgePoint(id: "nn_backpropagation", chapter: "模型训练", title: "反向传播", difficulty: 5, mastery: 0.24, status: .weak),
                KnowledgePoint(id: "nn_regularization", chapter: "泛化能力", title: "过拟合与正则化", difficulty: 4, mastery: 0.32, status: .weak),
                KnowledgePoint(id: "nn_cnn", chapter: "网络结构", title: "CNN", difficulty: 4, mastery: 0.38, status: .inProgress),
                KnowledgePoint(id: "nn_transformer", chapter: "网络结构", title: "Transformer", difficulty: 5, mastery: 0.26, status: .weak)
            ],
            questions: [
                QuizQuestion(
                    id: "q_nn_001",
                    courseID: "neural_network",
                    knowledgePointID: "nn_backpropagation",
                    type: "single_choice",
                    difficulty: "medium",
                    question: "反向传播算法的主要作用是什么？",
                    options: ["随机初始化权重", "计算损失函数对参数的梯度", "增加训练数据数量", "将模型转换为移动端格式"],
                    answer: "计算损失函数对参数的梯度",
                    explanation: "反向传播通过链式法则计算损失函数对各层参数的梯度，用于后续参数更新。"
                ),
                QuizQuestion(
                    id: "q_nn_002",
                    courseID: "neural_network",
                    knowledgePointID: "nn_regularization",
                    type: "true_false",
                    difficulty: "medium",
                    question: "正则化方法通常用于缓解模型过拟合。",
                    options: ["正确", "错误"],
                    answer: "正确",
                    explanation: "L1、L2、Dropout 等正则化方法都可以帮助模型提升泛化能力。"
                )
            ]
        ),
        Course(
            id: "cloud",
            name: "云计算",
            examDate: .finalPilotDate(month: 5, day: 14, hour: 9),
            difficulty: 4,
            colorKey: "blue",
            symbol: "cloud",
            knowledgePoints: [
                KnowledgePoint(id: "cloud_service_models", chapter: "云服务模型", title: "IaaS、PaaS、SaaS", difficulty: 2, mastery: 0.58, status: .inProgress),
                KnowledgePoint(id: "cloud_virtualization", chapter: "基础设施", title: "虚拟化", difficulty: 3, mastery: 0.44, status: .inProgress),
                KnowledgePoint(id: "cloud_container", chapter: "云原生", title: "容器与 Docker", difficulty: 3, mastery: 0.38, status: .inProgress),
                KnowledgePoint(id: "cloud_kubernetes", chapter: "云原生", title: "Kubernetes 基础", difficulty: 5, mastery: 0.22, status: .weak),
                KnowledgePoint(id: "cloud_serverless", chapter: "计算模型", title: "Serverless", difficulty: 4, mastery: 0.30, status: .weak),
                KnowledgePoint(id: "cloud_scaling", chapter: "弹性伸缩", title: "自动扩缩容", difficulty: 4, mastery: 0.34, status: .weak)
            ],
            questions: [
                QuizQuestion(
                    id: "q_cloud_001",
                    courseID: "cloud",
                    knowledgePointID: "cloud_service_models",
                    type: "single_choice",
                    difficulty: "easy",
                    question: "以下哪一项最接近 SaaS 的例子？",
                    options: ["虚拟机实例", "数据库运行环境", "在线文档协作软件", "裸金属服务器"],
                    answer: "在线文档协作软件",
                    explanation: "SaaS 指用户直接使用云端软件服务，不需要管理底层运行环境。"
                ),
                QuizQuestion(
                    id: "q_cloud_002",
                    courseID: "cloud",
                    knowledgePointID: "cloud_serverless",
                    type: "true_false",
                    difficulty: "medium",
                    question: "Serverless 表示完全没有服务器存在。",
                    options: ["正确", "错误"],
                    answer: "错误",
                    explanation: "Serverless 并不是没有服务器，而是开发者不需要直接管理服务器。"
                )
            ]
        ),
        Course(
            id: "multi_agent",
            name: "多智能体系统",
            examDate: nil,
            difficulty: 4,
            colorKey: "orange",
            symbol: "person.3.sequence",
            knowledgePoints: [
                KnowledgePoint(id: "mas_agent_basic", chapter: "基础概念", title: "Agent 基本概念", difficulty: 2, mastery: 0.55, status: .inProgress),
                KnowledgePoint(id: "mas_perception_action", chapter: "智能体结构", title: "感知、决策与行动", difficulty: 3, mastery: 0.42, status: .inProgress),
                KnowledgePoint(id: "mas_communication", chapter: "协作机制", title: "多智能体通信", difficulty: 4, mastery: 0.34, status: .weak),
                KnowledgePoint(id: "mas_coordination", chapter: "协作机制", title: "协作与协调", difficulty: 4, mastery: 0.36, status: .weak),
                KnowledgePoint(id: "mas_task_decomposition", chapter: "任务规划", title: "任务分解", difficulty: 3, mastery: 0.46, status: .inProgress),
                KnowledgePoint(id: "mas_consensus", chapter: "群体决策", title: "一致性与共识", difficulty: 5, mastery: 0.24, status: .weak)
            ],
            questions: [
                QuizQuestion(
                    id: "q_mas_001",
                    courseID: "multi_agent",
                    knowledgePointID: "mas_agent_basic",
                    type: "single_choice",
                    difficulty: "easy",
                    question: "在多智能体系统中，Agent 最核心的特征是什么？",
                    options: ["只负责存储数据", "能够感知环境并自主决策", "只能执行固定脚本", "只能和用户聊天"],
                    answer: "能够感知环境并自主决策",
                    explanation: "Agent 通常具备感知、决策和行动能力，可以根据环境变化自主选择行为。"
                ),
                QuizQuestion(
                    id: "q_mas_002",
                    courseID: "multi_agent",
                    knowledgePointID: "mas_coordination",
                    type: "true_false",
                    difficulty: "medium",
                    question: "多智能体协作中，协调机制的目标之一是减少多个 Agent 之间的冲突。",
                    options: ["正确", "错误"],
                    answer: "正确",
                    explanation: "协调机制用于让多个 Agent 在目标、资源或行动存在冲突时仍能有效协作。"
                )
            ]
        )
    ]

    static let tasks: [StudyTask] = [
        StudyTask(
            id: "task_nn_backprop",
            track: .exam,
            bucket: .must,
            title: "反向传播错题复盘",
            subtitle: "神经网络 · 模型训练",
            minutes: 35,
            reason: "高难度、高错误风险，且 5 月 13 考试更近。",
            linkedCourseID: "neural_network",
            status: .pending
        ),
        StudyTask(
            id: "task_cloud_serverless",
            track: .exam,
            bucket: .must,
            title: "Serverless 与容器对比",
            subtitle: "云计算 · 计算模型",
            minutes: 25,
            reason: "容易在概念题和场景题中混淆。",
            linkedCourseID: "cloud",
            status: .pending
        ),
        StudyTask(
            id: "task_mas_comm",
            track: .exam,
            bucket: .should,
            title: "多智能体通信速览",
            subtitle: "多智能体系统 · 协作机制",
            minutes: 20,
            reason: "同时服务课程复习和项目展示话术。",
            linkedCourseID: "multi_agent",
            status: .pending
        ),
        StudyTask(
            id: "task_career_pitch",
            track: .career,
            bucket: .should,
            title: "FinalPilot 项目 2 分钟介绍",
            subtitle: "校招 · 项目展示",
            minutes: 20,
            reason: "面试保温任务，短时间高收益。",
            linkedCourseID: nil,
            status: .pending
        ),
        StudyTask(
            id: "task_career_self_intro",
            track: .career,
            bucket: .should,
            title: "1 分钟自我介绍",
            subtitle: "校招 · 通用面试",
            minutes: 15,
            reason: "突发面试前的最低准备。",
            linkedCourseID: nil,
            status: .pending
        ),
        StudyTask(
            id: "task_skip_applications",
            track: .career,
            bucket: .skip,
            title: "新增大批量投递",
            subtitle: "校招 · 可延期",
            minutes: 45,
            reason: "考试窗口前收益低，建议 5 月 14 考后恢复。",
            linkedCourseID: nil,
            status: .deferred
        )
    ]

    static let careerEvents: [CareerEvent] = [
        CareerEvent(
            id: "career_demo",
            company: "示例科技",
            role: "iOS / AI 应用开发实习",
            round: "技术一面",
            date: .finalPilotDate(month: 5, day: 9, hour: 16),
            importance: 4,
            preparationStatus: "最低准备包已建立"
        )
    ]
}

