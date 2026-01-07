# modes/template/template.py
# -------------------------------------------------------------------------
# TEMPLATE MẪU CHO NAGIOS PLUGIN
# Hướng dẫn sử dụng:
# 1. Copy thư mục 'modes/template' thành 'modes/ten_feature_moi'
# 2. Đổi tên file 'template.py' thành 'ten_feature_moi.py'
# 3. Sửa hàm setup() để đăng ký tên lệnh CLI
# 4. Sửa hàm run() để viết logic kiểm tra
# -------------------------------------------------------------------------

from core.connection import OK, WARNING, CRITICAL, UNKNOWN

def setup(subparsers):
    """
    PHẦN 1: CẤU HÌNH GIAO DIỆN CLI
    Đăng ký tên lệnh con (sub-command) và các tham số đầu vào.
    """
    # [TODO]: Đặt tên lệnh CLI của bạn ở đây (ví dụ: 'check_index', 'check_users')
    COMMAND_NAME = 'template_check'
    DESCRIPTION = 'Mô tả ngắn gọn về chức năng của check này'

    parser = subparsers.add_parser(COMMAND_NAME, help=DESCRIPTION)

    # [TODO]: Thêm các tham số cần thiết (Optional)
    # Lưu ý: Các tham số global (-H, -u, -p) đã có sẵn, không cần thêm lại.
    parser.add_argument('-w', '--warn', type=float, default=10, help='Ngưỡng cảnh báo (Warning)')
    parser.add_argument('-c', '--crit', type=float, default=20, help='Ngưỡng lỗi (Critical)')
    
    # [BẮT BUỘC]: Không được sửa dòng dưới này.
    # Nó giúp hệ thống biết phải gọi hàm 'run' khi lệnh này được kích hoạt.
    parser.set_defaults(func=run)

def run(status, args):
    """
    PHẦN 2: LOGIC KIỂM TRA (CORE LOGIC)
    
    Args:
        status (dict): Kết quả của lệnh db.serverStatus() đã được cache.
                       Dùng cái này để lấy metric mà không cần query lại DB.
        args (Namespace): Chứa các tham số người dùng nhập (args.warn, args.crit...)
    
    Returns:
        tuple: (Message String, Exit Code)
    """
    try:
        # [TODO]: Viết logic lấy chỉ số của bạn ở đây
        # Ví dụ mẫu: Lấy Uptime của server
        # Dữ liệu nằm trong dict 'status'. Hãy in biến status ra để xem cấu trúc nếu cần.
        current_value = status.get('uptime', 0)
        
        # Format message hiển thị
        msg = f"Uptime is {current_value} seconds"

        # [TODO]: So sánh với ngưỡng (Threshold)
        # Logic mẫu: Nếu uptime nhỏ hơn threshold thì báo lỗi (ví dụ server vừa reboot)
        if current_value < args.crit:
            return f"CRITICAL - Uptime too low! {msg}", CRITICAL
        
        elif current_value < args.warn:
            return f"WARNING - Server recently restarted. {msg}", WARNING
        
        else:
            # Luôn trả về OK nếu mọi thứ bình thường
            return f"OK - {msg}", OK

    except KeyError as e:
        # Xử lý lỗi nếu key không tồn tại trong serverStatus
        return f"UNKNOWN - Metric key not found: {e}", UNKNOWN
    except Exception as e:
        # Xử lý các lỗi logic khác (chia cho 0, sai kiểu dữ liệu...)
        return f"UNKNOWN - Logic Error: {e}", UNKNOWN