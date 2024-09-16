/**
 * @author zhanglulu
 * @description 定义节点接口，表示工作流中的一个节点
 */
export interface Node {
  // 节点的唯一标识符
  id: string;
  // 可选的参数
  params?: object;
  // 后继节点的 ID 列表
  next: string[];
}