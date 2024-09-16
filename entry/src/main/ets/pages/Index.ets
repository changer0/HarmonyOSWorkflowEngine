import { Config, WorkflowEngine } from 'lib_workflow_engine';
import { LengthUnit, promptAction } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  readonly defaultLogMsg = "[欢迎使用工作流引擎]\n";
  @State logMsg: string = this.defaultLogMsg;
  scroller: Scroller = new Scroller()

  build() {
    Flex({ direction: FlexDirection.Column }) {

      Text('工作流引擎DEMO')
        .width('100%').height(50)
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Bold)

      Text('输出:').width('100%').height(50)
      Scroll(this.scroller) {
        Column() {
          Text(this.logMsg)
            .fontSize(15)
            .padding(5)// 设置行间距
            .lineSpacing({
              unit: LengthUnit.VP,
              value: 8
            })
            .width("100%")// .height("100%")
              // .align(Alignment.TopStart)
            .fontColor(Color.Green)
          // .backgroundColor(Color.Orange)

        }.width('100%')
      }.width("100%").height("60%")
      .align(Alignment.Top)
      .backgroundColor(Color.Black)

      Text('控制台:').width('100%').height(50)
      Scroll() {
        Column() {
          Button("执行工作流引擎")
            .id('click_engine')
            .width("100%")
            .fontSize(15)
            .onClick(async () => {
              this.scroller.scrollEdge(Edge.Bottom, { velocity: 700 })

              this.resetLogMsg()
              const workflowEngine = new WorkflowEngine(config);
              let that = this;
              workflowEngine.setLogger((msg) => {
                that.addLogMsg(msg)
              })
              workflowEngine.setNodeExecutor(async (node) => {
                await new Promise<void>(resolve => {
                  if (node.id === "Node4") {
                    // 如果是 Node4，延迟 5 秒执行完成，模拟耗时操作
                    setTimeout(() => {
                      this.addLogMsg(`节点 ${node.id} 执行完成`);
                      resolve();
                    }, 5 * 1000);
                  } else {
                    // 其他节点随机延迟一段时间执行完成
                    setTimeout(() => {
                      this.addLogMsg(`节点 ${node.id} 执行完成`);
                      resolve();
                    }, Math.random() * 1000);
                  }
                });
              })
              await workflowEngine.execute();
              this.addLogMsg(`全部流程执行完成🍺`);
              promptAction.showToast({ message: "全部流程执行完成!", alignment: Alignment.Bottom })
            })

        }.width('100%')
        .padding(10)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
      }.width("100%").height("30%")
      // 滚动方向纵向
      .scrollable(ScrollDirection.Vertical)
      .align(Alignment.Top)
    }
    .padding(10)
    .height('100%')
    .width('100%')
  }

  /**
   * 添加日志消息
   * @param msg
   */
  addLogMsg(msg: string) {
    msg = `${this.formatDate(new Date())} ${msg}`
    console.log(msg);
    this.logMsg += msg + "\n";
    this.scroller.scrollEdge(Edge.Bottom, { velocity: 700 })
  }

  /**
   * 格式化日期
   * @param date
   * @returns
   */
  formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = date.getMonth() + 1; // getMonth() returns 0-11
    const day = date.getDate();
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');
    return `${year}/${month}/${day}, ${hours}:${minutes}:${seconds}`;
  }

  /**
   * 重置日志消息
   */
  resetLogMsg() {
    this.logMsg = this.defaultLogMsg;
  }
}


// 示例配置（如提供的配置）
const configJson = `
{
  "nodes": [
    {
      "id": "Node1",
      "params":{
        "xx":"xx"
      },
      "next": ["Node2"]
    },
    {
      "id": "Node2",
      "next": ["Node3", "Node4", "Node5"]
    },
    {
      "id": "Node3",
      "next": ["Node6"]
    },
    {
      "id": "Node4",
      "next": ["Node7"]
    },
    {
      "id": "Node5",
      "next": ["Node7"]
    },
    {
      "id": "Node6",
      "next": ["Node7"]
    },
    {
      "id": "Node7",
      "next": ["Node8", "Node9", "Node10"]
    },
    {
      "id": "Node8",
      "next": ["Node11"]
    },
    {
      "id": "Node9",
      "next": ["Node11"]
    },
    {
      "id": "Node10",
      "next": ["Node11"]
    },
    {
      "id": "Node11",
      "next": []
    }
  ],
  "start": "Node1"
}
`;

// 解析配置，将 JSON 字符串转换为 Config 对象
const config: Config = JSON.parse(configJson);