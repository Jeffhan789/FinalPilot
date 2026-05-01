import Foundation

enum SeedData {
    static let courses: [Course] = [
        Course(
            id: "c310_multi_agent",
            name: "C310 多智能体系统",
            examDate: .finalPilotDate(month: 5, day: 13, hour: 9),
            difficulty: 5,
            colorKey: "orange",
            symbol: "person.3.sequence",
            knowledgePoints: [
                KnowledgePoint(id: "c310_agent_basic", chapter: "C1-C2", title: "Agent 基础、环境与 Expected Utility", difficulty: 3, mastery: 0.34, status: .weak),
                KnowledgePoint(id: "c310_bdi", chapter: "C3-C4", title: "演绎推理、BDI 与实践推理", difficulty: 5, mastery: 0.24, status: .weak),
                KnowledgePoint(id: "c310_architecture", chapter: "C5", title: "反应式与混合智能体架构", difficulty: 4, mastery: 0.30, status: .weak),
                KnowledgePoint(id: "c310_ontology", chapter: "C6&7", title: "本体论、通信与 Shared Ontology", difficulty: 4, mastery: 0.28, status: .weak),
                KnowledgePoint(id: "c310_cooperation", chapter: "C8-C11", title: "协同工作与多智能体交互", difficulty: 4, mastery: 0.32, status: .weak),
                KnowledgePoint(id: "c310_social_choice", chapter: "C12", title: "群体决策与 Social Choice", difficulty: 5, mastery: 0.22, status: .weak),
                KnowledgePoint(id: "c310_coalition", chapter: "C13", title: "联盟形成与 Coalition Formation", difficulty: 5, mastery: 0.20, status: .weak),
                KnowledgePoint(id: "c310_resource", chapter: "C14", title: "稀缺资源分配", difficulty: 4, mastery: 0.26, status: .weak),
                KnowledgePoint(id: "c310_negotiation", chapter: "C15-C16", title: "谈判协商与论证", difficulty: 4, mastery: 0.24, status: .weak),
                KnowledgePoint(id: "c310_planning", chapter: "C18", title: "高级自动规划", difficulty: 5, mastery: 0.18, status: .weak)
            ],
            questions: [
                QuizQuestion(
                    id: "q_c310_001",
                    courseID: "c310_multi_agent",
                    knowledgePointID: "c310_agent_basic",
                    type: "single_choice",
                    difficulty: "easy",
                    question: "在 C310 中，Agent 最核心的特征是什么？",
                    options: ["只负责存储数据", "能够在环境中感知并自主行动", "只能执行固定脚本", "只能和用户聊天"],
                    answer: "能够在环境中感知并自主行动",
                    explanation: "C310 Day 1 计划强调 agent、autonomy、environment、rationality 和 expected utility。"
                ),
                QuizQuestion(
                    id: "q_c310_002",
                    courseID: "c310_multi_agent",
                    knowledgePointID: "c310_bdi",
                    type: "single_choice",
                    difficulty: "medium",
                    question: "BDI 架构中的 intention 更接近下列哪一项？",
                    options: ["环境中的所有事实", "智能体已承诺执行的目标或计划", "随机生成的动作", "不需要筛选的所有 desire"],
                    answer: "智能体已承诺执行的目标或计划",
                    explanation: "BDI 的复习重点是 belief、desire、intention、deliberation、means-end reasoning 与 plan。"
                )
            ]
        ),
        Course(
            id: "e320_neural_network",
            name: "E320 神经网络",
            examDate: .finalPilotDate(month: 5, day: 14, hour: 9),
            difficulty: 5,
            colorKey: "teal",
            symbol: "point.3.connected.trianglepath.dotted",
            knowledgePoints: [
                KnowledgePoint(id: "e320_intro_structure", chapter: "C1-C2", title: "NN 引言、结构特性与符号表", difficulty: 3, mastery: 0.38, status: .inProgress),
                KnowledgePoint(id: "e320_learning", chapter: "C3", title: "学习过程、训练/验证/测试", difficulty: 3, mastery: 0.34, status: .weak),
                KnowledgePoint(id: "e320_perceptron", chapter: "C4", title: "单层感知机与 Decision Boundary", difficulty: 4, mastery: 0.30, status: .weak),
                KnowledgePoint(id: "e320_backprop", chapter: "C5", title: "MLP 与 Backpropagation", difficulty: 5, mastery: 0.20, status: .weak),
                KnowledgePoint(id: "e320_rbf", chapter: "C6", title: "RBF 网络", difficulty: 4, mastery: 0.24, status: .weak),
                KnowledgePoint(id: "e320_svm", chapter: "C7", title: "SVM", difficulty: 5, mastery: 0.22, status: .weak),
                KnowledgePoint(id: "e320_som", chapter: "C8", title: "SOM 算法步骤", difficulty: 4, mastery: 0.24, status: .weak),
                KnowledgePoint(id: "e320_modern", chapter: "C9-C10", title: "现代网络与总复习", difficulty: 4, mastery: 0.26, status: .weak)
            ],
            questions: [
                QuizQuestion(
                    id: "q_e320_001",
                    courseID: "e320_neural_network",
                    knowledgePointID: "e320_backprop",
                    type: "single_choice",
                    difficulty: "medium",
                    question: "Backpropagation 的主要作用是什么？",
                    options: ["随机初始化权重", "计算 loss 对参数的梯度并更新权重", "删除 hidden layer", "把模型转换为移动端格式"],
                    answer: "计算 loss 对参数的梯度并更新权重",
                    explanation: "E320 计划把 backprop 拆成 forward、error、output delta、hidden delta、weight update 五步。"
                ),
                QuizQuestion(
                    id: "q_e320_002",
                    courseID: "e320_neural_network",
                    knowledgePointID: "e320_perceptron",
                    type: "true_false",
                    difficulty: "medium",
                    question: "Perceptron 复习时只需要记结论，不需要写出 weight update rule。",
                    options: ["正确", "错误"],
                    answer: "错误",
                    explanation: "实际计划要求默写 perceptron decision rule 和 weight update rule，并手写计算题。"
                )
            ]
        ),
        Course(
            id: "c315_cloud",
            name: "C315 电子商务云计算",
            examDate: .finalPilotDate(month: 5, day: 26, hour: 9),
            difficulty: 4,
            colorKey: "blue",
            symbol: "cloud",
            knowledgePoints: [
                KnowledgePoint(id: "c315_service_models", chapter: "云服务模型", title: "IaaS、PaaS、SaaS", difficulty: 2, mastery: 0.48, status: .inProgress),
                KnowledgePoint(id: "c315_virtualization", chapter: "基础设施", title: "虚拟化", difficulty: 3, mastery: 0.40, status: .inProgress),
                KnowledgePoint(id: "c315_container", chapter: "云原生", title: "容器与 Docker", difficulty: 3, mastery: 0.34, status: .weak),
                KnowledgePoint(id: "c315_kubernetes", chapter: "云原生", title: "Kubernetes 基础", difficulty: 5, mastery: 0.24, status: .weak),
                KnowledgePoint(id: "c315_serverless", chapter: "计算模型", title: "Serverless", difficulty: 4, mastery: 0.30, status: .weak),
                KnowledgePoint(id: "c315_scaling", chapter: "弹性伸缩", title: "自动扩缩容", difficulty: 4, mastery: 0.30, status: .weak)
            ],
            questions: [
                QuizQuestion(
                    id: "q_c315_001",
                    courseID: "c315_cloud",
                    knowledgePointID: "c315_service_models",
                    type: "single_choice",
                    difficulty: "easy",
                    question: "以下哪一项最接近 SaaS 的例子？",
                    options: ["虚拟机实例", "数据库运行环境", "在线文档协作软件", "裸金属服务器"],
                    answer: "在线文档协作软件",
                    explanation: "SaaS 指用户直接使用云端软件服务，不需要管理底层运行环境。"
                ),
                QuizQuestion(
                    id: "q_c315_002",
                    courseID: "c315_cloud",
                    knowledgePointID: "c315_serverless",
                    type: "true_false",
                    difficulty: "medium",
                    question: "Serverless 表示完全没有服务器存在。",
                    options: ["正确", "错误"],
                    answer: "错误",
                    explanation: "Serverless 并不是没有服务器，而是开发者不需要直接管理服务器。"
                )
            ]
        )
    ]

    static let tasks: [StudyTask] = [
        StudyTask(
            id: "task_c310_day1",
            track: .exam,
            bucket: .must,
            title: "C310 C1-C2 Agent 基础闭环",
            subtitle: "C310 · Agent / Environment / EU",
            minutes: 70,
            reason: "真实计划 Day 1：精读 C1-C2，输出术语表、Agent definition 和环境属性比较。",
            linkedCourseID: "c310_multi_agent",
            status: .pending
        ),
        StudyTask(
            id: "task_e320_day1",
            track: .exam,
            bucket: .must,
            title: "E320 C1-C2 网络结构与符号表",
            subtitle: "E320 · NN 引言 / 结构特性",
            minutes: 60,
            reason: "E320 只晚一天考试，不能等 C310 考完再开始；今天要建立公式和术语页。",
            linkedCourseID: "e320_neural_network",
            status: .pending
        ),
        StudyTask(
            id: "task_c310_truth_matrix",
            track: .exam,
            bucket: .should,
            title: "C310 真题矩阵定位 Q1",
            subtitle: "C310 · 09/10、10/11、12/13、15/16、17/18",
            minutes: 35,
            reason: "计划要求不要等课件全过完才碰真题，今天先定位 Q1 类题。",
            linkedCourseID: "c310_multi_agent",
            status: .pending
        ),
        StudyTask(
            id: "task_e320_structure_output",
            track: .exam,
            bucket: .should,
            title: "E320 手画 2-input 小网络",
            subtitle: "E320 · 输入、权重、bias、activation、output",
            minutes: 30,
            reason: "今天的完成标准不是看完，而是能画结构图并写变量含义。",
            linkedCourseID: "e320_neural_network",
            status: .pending
        ),
        StudyTask(
            id: "task_career_buffer",
            track: .career,
            bucket: .should,
            title: "面试 / 突发缓冲",
            subtitle: "Career Track · 1.5-2 小时保护区",
            minutes: 90,
            reason: "真实总控要求每天预留缓冲；有面试就处理面试，没有面试就做术语默写和轻量主动回忆。",
            linkedCourseID: nil,
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
            id: "task_skip_c315_deep",
            track: .exam,
            bucket: .skip,
            title: "C315 深度复习",
            subtitle: "C315 · 5 月 26 日考试",
            minutes: 60,
            reason: "C315 在 5 月 26 日，当前阶段只保留低频保温，不抢 C310/E320 的黄金时间。",
            linkedCourseID: "c315_cloud",
            status: .deferred
        ),
        StudyTask(
            id: "task_skip_applications",
            track: .career,
            bucket: .skip,
            title: "新增大批量投递",
            subtitle: "校招 · 可延期",
            minutes: 45,
            reason: "5 月 13/14 连续考试前收益低，建议 E320 考后恢复。",
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

