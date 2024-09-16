import { Config } from './Config';
import { Node } from './Node';

/**
 * @author zhanglulu
 * @description 工作流引擎类，实现节点的调度和执行
 */
export class WorkflowEngine {
  // 配置信息
  private config: Config;
  // 节点映射，将节点 ID 映射到 Node 对象，便于快速查找
  private nodeMap: Map<string, Node> = new Map();
  // 前驱节点映射，每个节点对应一个前驱节点的集合，用于判断节点是否可以执行
  private predecessors: Map<string, Set<string>> = new Map();
  // 已完成的节点集合，用于记录哪些节点已经执行完成
  private completedNodes: Set<string> = new Set();
  // 正在执行的节点集合，防止重复执行
  private executingNodes: Set<string> = new Set();
  // 用于等待所有节点执行完成的 Promise
  private executionPromise: Promise<void>;
  // 用于在所有节点执行完成时触发的 resolve 函数
  private resolveExecution?: () => void;
  // Logger
  private loggerEntity: ((msg: string) => void) | undefined = undefined;
  // 真正执行节点的函数
  private nodeExecutor: ((node: Node) => Promise<void>) | undefined = undefined;

  /**
   * 构造函数，接受配置对象并初始化
   * @param config
   */
  constructor(config: Config) {
    // 配置信息
    this.config = config;
    // 构建节点映射
    this.buildNodeMap();
    // 构建前驱节点映射
    this.buildPredecessors();

    // 在构造函数中初始化 executionPromise，并获取 resolve 函数
    this.executionPromise = new Promise<void>(resolve => {
      this.resolveExecution = resolve;
    });
  }

  /**
   * 设置 Logger
   * @param logger
   */
  public setLogger(logger: (msg: string) => void) {
    this.loggerEntity = logger;
  }

  /**
   * 设置节点执行函数，用于执行实际的节点逻辑
   * @param nodeExecutor
   */
  public setNodeExecutor(nodeExecutor: (node: Node) => Promise<void>) {
    this.nodeExecutor = nodeExecutor;
  }

  /**
   * 日志打印
   * @param msg
   */
  private log(msg: string) {
    if (this.loggerEntity) {
      this.loggerEntity(msg);
    } else {
      console.log(msg);
    }
  }

  /**
   * 构建节点映射，方便通过节点 ID 快速获取节点信息
   */
  private buildNodeMap() {
    this.config.nodes.forEach(node => {
      this.nodeMap.set(node.id, node);
    });
  }

  /**
   * 构建前驱节点映射，初始化每个节点的前驱节点集合
   */
  private buildPredecessors() {
    // 初始化所有节点的前驱集合为空集合
    this.config.nodes.forEach(node => {
      if (!this.predecessors.has(node.id)) {
        this.predecessors.set(node.id, new Set());
      }
    });

    // 遍历所有节点，填充后继节点的前驱集合
    this.config.nodes.forEach(node => {
      node.next.forEach(nextNodeId => {
        if (!this.predecessors.has(nextNodeId)) {
          this.predecessors.set(nextNodeId, new Set());
        }
        // 将当前节点添加到后继节点的前驱集合中
        this.predecessors.get(nextNodeId)?.add(node.id);
      });
    });
  }

  /**
   * 执行工作流
   */
  public async execute() {
    // 存放准备好的节点
    const readyNodes = new Set<string>();

    // 找出所有没有前驱节点的节点，即可立即执行的节点
    for (let entriesElement of this.predecessors.entries()) {
      // 遍历所有前驱节点集合
      let nodeId = entriesElement[0];
      let preds = entriesElement[1];
      // 如果前驱集合为空，说明没有前驱节点，即可立即执行
      if (preds.size === 0) {
        readyNodes.add(nodeId);
      }
    }

    // 开始执行所有准备好的节点
    readyNodes.forEach(nodeId => {
      // 异步执行节点
      this.executeNode(nodeId);
    });

    // 等待所有节点执行完成
    await this.executionPromise;
  }

  /**
   * 执行单个节点
   * @param nodeId
   */
  private async executeNode(nodeId: string) {
    // 如果节点正在执行或已完成，直接返回，防止重复执行
    if (this.executingNodes.has(nodeId) || this.completedNodes.has(nodeId)) {
      return;
    }
    // 标记节点为正在执行
    this.executingNodes.add(nodeId);
    // 获取节点对象，使用断言节点一定存在
    const node = this.nodeMap.get(nodeId);
    if (!node) {
      return;
    }
    this.log(`正在执行节点 ${node.id}`);
    if (!this.nodeExecutor) {
      throw new Error("NodeExecutor is not set!");
      return;
    }
    // 真正的执行逻辑
    await this.nodeExecutor?.(node);
    // 将节点标记为已完成
    this.completedNodes.add(nodeId);
    // 从正在执行的集合中移除
    this.executingNodes.delete(nodeId);

    // 检查是否所有节点都已完成
    if (this.completedNodes.size === this.nodeMap.size) {
      // 触发流程执行完成的 Promise
      this.resolveExecution?.();
    }

    // 处理后继节点，检查它们是否可以执行
    node.next.forEach(nextNodeId => {
      // 获取后继节点的前驱集合
      const preds = this.predecessors.get(nextNodeId);
      // 从前驱集合中移除当前已完成的节点
      preds?.delete(nodeId);
      if (preds?.size === 0) {
        // 如果前驱集合为空，说明后继节点的所有前驱都已完成，可以开始执行
        this.executeNode(nextNodeId);
      }
    });
  }
}