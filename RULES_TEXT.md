# 人格计算规则（文本版）

## 1. 题目与维度
- 普通题共 30 题，按 15 个维度计分，每个维度包含 2 题。
- 维度顺序固定为：S1, S2, S3, E1, E2, E3, A1, A2, A3, Ac1, Ac2, Ac3, So1, So2, So3。

## 2. 维度计分与等级
- 每题分值范围：1 到 3。
- 每个维度得分为该维度两题分值之和。
- 等级映射：
  - score <= 3 -> L
  - score = 4 -> M
  - score >= 5 -> H
- 数值映射：L = 1, M = 2, H = 3。
- 由此得到用户 15 维向量 userVector。

## 3. 普通人格匹配
- 对每个普通人格，将 pattern（例如 HHH-HMH-MHH-HHH-MHM）转换为 15 维 typeVector。
- 距离计算：distance = Σ|userVector[i] - typeVector[i]|，最大值为 30。
- 完全匹配维数：exact = 差值为 0 的维度数。
- 相似度计算：similarity = max(0, round((1 - distance / 30) * 100))。
- 排序规则：distance 升序 -> exact 降序 -> similarity 降序。
- 排序第一名记为 bestNormal。

## 4. 特殊规则
- 触发人格 DRUNK：
  - 如果补充题 drink_gate_q2 的答案值等于 2，直接激活 DRUNK。
  - 命中后相似度强制为 100。
- 兜底人格 HHHH：
  - 如果 bestNormal.similarity < 60，则强制兜底为 HHHH。

## 5. 最终人格决策
- 最终优先级：DRUNK > HHHH > bestNormal。

## 6. 展示信息来源
- 人格文案（cn, intro, desc）由 TYPE_LIBRARY.json 提供。
- 人格结构信息（code, kind, pattern, rule）由 PERSONALITY_STRUCTURE.json 提供。
