# -*- coding: utf-8 -*-
"""生成 hospital 项目的功能模块图（学术黑白线框，矢量 SVG + 高分辨率 PNG）"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

matplotlib.rcParams["font.sans-serif"] = ["SimHei"]
matplotlib.rcParams["font.family"] = "sans-serif"
matplotlib.rcParams["axes.unicode_minus"] = False
matplotlib.rcParams["svg.fonttype"] = "path"

OUT = r"D:\hospital\docs\figures"
os.makedirs(OUT, exist_ok=True)

BLACK = "#000000"
LW_BOX = 0.9
LW_LINE = 0.8


def new_axes(W, H):
    fig = plt.figure(figsize=(W / 72.0, H / 72.0))
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, W)
    ax.set_ylim(H, 0)
    ax.axis("off")
    return fig, ax


def box(ax, x, y, w, h, text, fs=16, lw=LW_BOX):
    ax.add_patch(Rectangle((x, y), w, h, facecolor="white", edgecolor=BLACK,
                           linewidth=lw, zorder=3, joinstyle="miter"))
    ax.text(x + w / 2.0, y + h / 2.0, text, ha="center", va="center",
            fontsize=fs, color=BLACK, zorder=4)


def poly(ax, pts, lw=LW_LINE):
    ax.plot([p[0] for p in pts], [p[1] for p in pts], color=BLACK,
            linewidth=lw, solid_capstyle="butt", solid_joinstyle="miter", zorder=2)


# ============================================================
# 图 1：按业务模块组织的功能模块图
# ============================================================
MODULES = [
    ("用户权限管理", ["登录认证", "用户注册", "角色分配", "密码维护"]),
    ("医生信息管理", ["医生查询", "医生添加", "医生修改", "医生删除"]),
    ("病人信息管理", ["病人查询", "病人添加", "病人修改", "病人删除"]),
    ("病床信息管理", ["病床查询", "病床添加", "病床修改", "使用状态"]),
    ("挂号排班管理", ["在线挂号", "挂号记录", "排班维护", "我的接诊"]),
    ("病历管理",     ["病历录入", "病历查询", "病历编辑"]),
    ("处方药库管理", ["开方开药", "我的处方", "药品库存", "处方发药"]),
    ("收费费用管理", ["收费录入", "收费查询", "病人费用", "费用调整"]),
    ("统计查询分析", ["病床利用率", "收费明细", "数据看板", "报表导出"]),
    ("智能导诊服务", ["症状问答", "对话历史", "模型配置", "接口配置"]),
]

W1, H1 = 980, 930
PITCH = 182
LEFT0 = 55
MOD_W, MOD_H = 150, 54
CHILD_W, CHILD_H = 132, 46
ROW1_Y, ROW2_Y = 170, 580
CHILD_DY = 60

fig, ax = new_axes(W1, H1)

# 根节点
ROOT_CX = 494
box(ax, ROOT_CX - 150, 40, 300, 54, "医院信息管理系统", fs=19, lw=1.6)

BUS1_Y, BUS2_Y = 150, 560
BUS_L, BUS_R = 120, 868
# 换行线走第 1、2 列子树之间的空隙，避免与母线围合成框
WRAP_X, WRAP_JOG_Y = 221, 118

# 主干：根 -> 母线1
poly(ax, [(ROOT_CX, 94), (ROOT_CX, BUS1_Y)])
# 母线1
poly(ax, [(BUS_L, BUS1_Y), (BUS_R, BUS1_Y)])
# 换行线：主干分叉 -> 列间空隙下行 -> 母线2
poly(ax, [(ROOT_CX, WRAP_JOG_Y), (WRAP_X, WRAP_JOG_Y),
          (WRAP_X, BUS2_Y), (BUS_L, BUS2_Y)])
poly(ax, [(WRAP_X, BUS2_Y), (BUS_R, BUS2_Y)])

for idx, (name, children) in enumerate(MODULES):
    row = 0 if idx < 5 else 1
    col = idx % 5
    L = LEFT0 + col * PITCH
    cx = L + MOD_W / 2.0
    my = ROW1_Y if row == 0 else ROW2_Y
    bus_y = BUS1_Y if row == 0 else BUS2_Y

    poly(ax, [(cx, bus_y), (cx, my)])
    box(ax, L, my, MOD_W, MOD_H, name, fs=16)

    spine_x = L + 9
    child_x = L + 18
    y0 = my + MOD_H + 26
    centers = [y0 + CHILD_H / 2.0 + i * CHILD_DY for i in range(len(children))]

    poly(ax, [(spine_x, my + MOD_H), (spine_x, centers[-1])])
    for cy, cname in zip(centers, children):
        poly(ax, [(spine_x, cy), (child_x, cy)])
        box(ax, child_x, cy - CHILD_H / 2.0, CHILD_W, CHILD_H, cname, fs=13.5, lw=0.8)

fig.savefig(os.path.join(OUT, "图1-系统功能模块图.svg"), format="svg",
            facecolor="white", bbox_inches=None)
fig.savefig(os.path.join(OUT, "图1-系统功能模块图.png"), dpi=220,
            facecolor="white", bbox_inches=None)
plt.close(fig)
print("图1 done")

# ============================================================
# 图 2：按角色划分的功能模块图
# ============================================================
ROLES = [
    ("管理员", ["医生信息管理", "病床信息管理", "病人信息管理", "收费信息管理",
                "挂号管理", "统计分析", "智能服务", "系统管理"]),
    ("医生",   ["我的档案", "我的病人", "我的接诊", "我的病历", "病历录入",
                "我的排班", "药品库存", "开方开药", "我的处方", "病人费用"]),
    ("病人",   ["我的信息", "我要挂号", "我的挂号", "我的病历", "我的费用",
                "智能导诊"]),
]

W2 = 900
COL_W = 200
COL_X = [70, 350, 630]
ITEM_W, ITEM_H = 168, 42
ITEM_DY = 54
ROLE_Y, ROLE_H = 160, 52
ITEM_Y0 = 250
max_items = max(len(r[1]) for r in ROLES)
H2 = ITEM_Y0 + (max_items - 1) * ITEM_DY + ITEM_H + 45

fig, ax = new_axes(W2, H2)

RCX = 450
box(ax, RCX - 140, 40, 280, 54, "医院信息管理系统", fs=19, lw=1.6)
BUS_Y = 140
poly(ax, [(RCX, 94), (RCX, BUS_Y)])
poly(ax, [(COL_X[0] + COL_W / 2.0, BUS_Y), (COL_X[2] + COL_W / 2.0, BUS_Y)])

for i, (role, items) in enumerate(ROLES):
    cx = COL_X[i] + COL_W / 2.0
    poly(ax, [(cx, BUS_Y), (cx, ROLE_Y)])
    box(ax, COL_X[i], ROLE_Y, COL_W, ROLE_H, role, fs=17, lw=1.2)

    spine_x = COL_X[i] + 8
    item_x = COL_X[i] + 16
    centers = [ITEM_Y0 + ITEM_H / 2.0 + k * ITEM_DY for k in range(len(items))]
    poly(ax, [(spine_x, ROLE_Y + ROLE_H), (spine_x, centers[-1])])
    for cy, iname in zip(centers, items):
        poly(ax, [(spine_x, cy), (item_x, cy)])
        box(ax, item_x, cy - ITEM_H / 2.0, ITEM_W, ITEM_H, iname, fs=14.5, lw=0.8)

fig.savefig(os.path.join(OUT, "图2-角色功能模块图.svg"), format="svg", facecolor="white")
fig.savefig(os.path.join(OUT, "图2-角色功能模块图.png"), dpi=220, facecolor="white")
plt.close(fig)
print("图2 done")
print("输出目录:", OUT)
