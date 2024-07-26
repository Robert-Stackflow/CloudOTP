# 遍历文件夹下的json文件，对于每个json文件生成对应的代码
# 如对于gift_dark.json，对应代码行为static const String giftDark = "assets/lottie/gift_dark.json"
# 生成所有json文件对应的代码，并写入到文件中
import os


def to_camel_case(snake_str):
    """将蛇形命名（下划线分隔）转换为驼峰命名（首字母小写）"""
    components = snake_str.split("_")
    return components[0].lower() + "".join(x.title() for x in components[1:])


def generate_code_for_json_files(folder_path, output_file):
    # 初始化一个列表来存储所有的代码行
    code_lines = []

    # 遍历文件夹下的所有文件
    for root, _, files in os.walk(folder_path):
        for file in files:
            if file.endswith(".png"):
                # 提取文件名（不包括扩展名）
                base_name = os.path.splitext(file)[0]
                # 将文件名转换为驼峰命名
                variable_name = to_camel_case(base_name) + "Icon"
                # 生成代码行
                code_line = (
                    f'static const String {variable_name} = "assets/icon/{file}";'
                )
                # 将代码行添加到列表中
                code_lines.append(code_line)

    # 将所有代码行写入到输出文件中
    with open(output_file, "w") as f:
        for line in code_lines:
            f.write(line + "\n")


# 使用示例
folder_path = "./"  # 替换为你的文件夹路径
output_file = "./code.txt"  # 替换为你的输出文件路径
generate_code_for_json_files(folder_path, output_file)
