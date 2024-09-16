import { Node } from './Node';

// 定义配置接口，包含所有节点
export interface Config {
  nodes: Node[]; // 节点列表
}