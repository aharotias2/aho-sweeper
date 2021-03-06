/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 * Copyright 2021 Takayuki Tanaka
 */

namespace Aho {
    public const string RULE_DESCRIPTION = "ルール\n"
        + "マインスイーパのルールは非常に単純です。"
        + "ボードはセルに分割され、地雷はランダムに分散されています。"
        + "勝つには、すべてのセルを開く必要があります。"
        + "セルの数字は、それに隣接する地雷の数を示しています。"
        + "この情報を使用して、安全なセルと地雷を含むセルを判別できます。"
        + "地雷であると疑われる細胞は、マウスの右ボタンを使用してフラグでマークすることができます。";
        
    public const string[] LETTERS = { "0", "1", "2", "3", "4", "5", "6", "7", "8" };

    public enum ModelSize {
        MODEL_9X9,
        MODEL_16X16,
        MODEL_30X30
        ;

        public int get_x_length() {
            switch (this) {
              default:
              case MODEL_9X9:
                return 9;
              case MODEL_16X16:
                return 16;
              case MODEL_30X30:
                return 30;
            }
        }

        public int get_y_length() {
            switch (this) {
              default:
              case MODEL_9X9:
                return 9;
              case MODEL_16X16:
                return 16;
              case MODEL_30X30:
                return 30;
            }
        }
        
        public string to_string() {
            switch (this) {
              default:
              case MODEL_9X9:
                return "9x9";
              case MODEL_16X16:
                return "16x16";
              case MODEL_30X30:
                return "30x30";
            }
        }
        
        public static ModelSize from_string(string id) {
            switch (id) {
              default:
              case "9x9":
                return MODEL_9X9;
              case "16x16":
                return MODEL_16X16;
              case "30x30":
                return MODEL_30X30;
            }
        }
        
        public static ModelSize[] all() {
            return { MODEL_9X9, MODEL_16X16, MODEL_30X30 };
        }
    }

    public struct Cell {
        public bool has_bomb;
        public bool is_closed;
        public bool is_fixed;
        public int number;
    }

    public interface Drawer {
        public abstract bool draw(Cairo.Context cairo);
    }

    public enum Theme {
        LIGHT,
        DARK
    }
        
    public class SweeperModel : Object {
        public signal void started();
        public signal void win();
        public signal void lose(int cell_y, int cell_x);
        
        private ModelSize size;
        private int appearance_rate;
        private int x_length_value;
        private int y_length_value;
        private Cell[,] cells;
        private bool is_playing = false;
        
        public SweeperModel(ModelSize size) {
            this.size = size;
            is_playing = false;
            appearance_rate = 6;
            x_length_value = size.get_x_length();
            y_length_value = size.get_y_length();
            cells = new Cell[y_length_value, x_length_value];
            for (int j = 0; j < y_length; j++) {
                for (int i = 0; i < x_length; i++) {
                    cells[j, i].is_closed = true;
                    cells[j, i].has_bomb = false;
                    cells[j, i].is_fixed = false;
                    cells[j, i].number = 0;
                }
            }
        }

        public int x_length {
            get {
                return x_length_value;
            }
        }

        public int y_length {
            get {
                return y_length_value;
            }
        }

        public int get_number(int y, int x) {
            return cells[y, x].number;
        }

        public bool is_closed(int y, int x) {
            return cells[y, x].is_closed;
        }

        public bool has_bomb(int y, int x) {
            return cells[y, x].has_bomb;
        }

        public bool is_fixed(int y, int x) {
            return cells[y, x].is_fixed;
        }
        
        public void fix(int y, int x) {
            cells[y, x].is_fixed = true;
        }
        
        public void unfix(int y, int x) {
            cells[y, x].is_fixed = false;
        }

        public void close_cell(int y, int x) {
            cells[y, x].is_closed = true;
        }
                
        public bool open_cell(int y, int x) {
            if (!is_playing) {
                generate_game(y, x);
                is_playing = true;
                started();
            }
            bool result = open_cell_recursively(y, x, false);
            if (!result) {
                lose(y, x);
                return false;
            } else if (check_is_win()) {
                win();
                return true;
            } else {
                return true;
            }
        }

        private void generate_game(int y, int x) {
            Random.set_seed((uint32) new DateTime.now_local().to_unix());
            for (int j = 0; j < y_length_value; j++) {
                for (int i = 0; i < x_length_value; i++) {
                    bool is_safe = false;
                    if (y > 0 && x > 0) {
                        if (j == y - 1 && i == x - 1) {
                            is_safe = true;
                        }
                    }
                    if (y > 0) {
                        if (j == y - 1 && i == x) {
                            is_safe = true;
                        }
                    }
                    if (y > 0 && x + 1 < x_length) {
                        if (j == y - 1 && i == x + 1) {
                            is_safe = true;
                        }
                    }
                    if (x > 0) {
                        if (j == y && i == x - 1) {
                            is_safe = true;
                        }
                    }
                    if (j == y && i == x) {
                        is_safe = true;
                    }
                    if (x + 1 < x_length) {
                        if (j == y && i == x + 1) {
                            is_safe = true;
                        }
                    }
                    if (y + 1 < y_length && x > 0) {
                        if (j == y + 1 && i == x - 1) {
                            is_safe = true;
                        }
                    }
                    if (y + 1 < y_length) {
                        if (j == y + 1 && i == x) {
                            is_safe = true;
                        }
                    }
                    if (y + 1 < y_length && x + 1 < x_length) {
                        if (j == y + 1 && i == x + 1) {
                            is_safe = true;
                        }
                    }

                    if (is_safe) {
                        cells[j, i].has_bomb = false;
                    } else {
                        cells[j, i].has_bomb = Random.int_range(0, appearance_rate) == 0;
                    }

                    cells[j, i].is_closed = true;
                }
            }
            for (int j = 0; j < y_length_value; j++) {
                for (int i = 0; i < x_length_value; i++) {
                    cells[j, i].number = number_of_adjacent_bombs(j, i);
                }
            }
        }
        
        private bool open_cell_recursively(int y, int x, bool is_recursive) {
            if (!cells[y, x].is_closed) {
                return true;
            } else if (cells[y, x].has_bomb) {
                if (!is_recursive) {
                    cells[y, x].is_closed = false;
                    return false;
                } else {
                    return true;
                }
            } else {
                if (!is_recursive) {
                    cells[y, x].is_closed = false;
                    if (cells[y, x].number > 0) {
                        return true;
                    }
                } else {
                    cells[y, x].is_closed = false;
                    if (cells[y, x].number > 0) {
                        return true;
                    }
                }
                if (y > 0 && x > 0) {
                    open_cell_recursively(y - 1, x - 1, true);
                }
                if (y > 0) {
                    open_cell_recursively(y - 1, x, true);
                }
                if (y > 0 && x + 1 < x_length) {
                    open_cell_recursively(y - 1, x + 1, true);
                }
                if (x > 0) {
                    open_cell_recursively(y, x - 1, true);
                }
                if (x + 1 < x_length) {
                    open_cell_recursively(y, x + 1, true);
                }
                if (y + 1 < y_length && x > 0) {
                    open_cell_recursively(y + 1, x - 1, true);
                }
                if (y + 1 < y_length) {
                    open_cell_recursively(y + 1, x, true);
                }
                if (y + 1 < y_length && x + 1 < x_length) {
                    open_cell_recursively(y + 1, x + 1, true);
                }
                return true;
            }
        }

        private int number_of_adjacent_bombs(int y, int x) {
            int count = 0;
            if (y > 0 && x > 0) {
                count += cells[y - 1, x - 1].has_bomb ? 1 : 0;
            }
            if (y > 0) {
                count += cells[y - 1, x].has_bomb ? 1 : 0;
            }
            if (y > 0 && x + 1 < x_length) {
                count += cells[y - 1, x + 1].has_bomb ? 1 : 0;
            }
            if (x > 0) {
                count += cells[y, x - 1].has_bomb ? 1 : 0;
            }
            if (x + 1 < x_length) {
                count += cells[y, x + 1].has_bomb ? 1 : 0;
            }
            if (y + 1 < y_length && x > 0) {
                count += cells[y + 1, x - 1].has_bomb ? 1 : 0;
            }
            if (y + 1 < y_length) {
                count += cells[y + 1, x].has_bomb ? 1 : 0;
            }
            if (y + 1 < y_length && x + 1 < x_length) {
                count += cells[y + 1, x + 1].has_bomb ? 1 : 0;
            }
            return count;
        }
        
        private bool check_is_win() {
            for (int y = 0; y < y_length; y++) {
                for (int x = 0; x < x_length; x++) {
                    if (cells[y, x].is_closed && !cells[y, x].has_bomb) {
                        return false;
                    }
                }
            }
            return true;
        }
    }

    public class SparkDrawer : Drawer {
        public struct Point {
            public double initial_x;
            public double initial_y;
            public double x;
            public double y;
            public double radians;
            public Gdk.RGBA color;
        }

        public bool running { get; set; }
        
        private double x;
        private double y;
        private int num_of_dots;
        private Point[] dots;
        private double times;
        private double radius;
        private double moving_amount;
        private double radians_360_degrees;
        
        public SparkDrawer(double start_y, double start_x) {
            this.y = start_y;
            this.x = start_x;
            num_of_dots = 10;
            radius = 0.1;
            moving_amount = 10.0;
            radians_360_degrees = Math.PI * 2.0;
            dots = new Point[num_of_dots];
            for (int i = 0; i < num_of_dots; i++) {
                dots[i].initial_x = start_x;
                dots[i].initial_y = start_y;
                dots[i].x = start_x;
                dots[i].y = start_y;
                dots[i].radians = radians_360_degrees / (double) num_of_dots * (double) i;
                double red = Random.double_range(0.1, 0.9);
                double green = Random.double_range(0.1, 0.9);
                double blue = Random.double_range(0.1, 0.9);
                dots[i].color = { red, green, blue, 1.0 };
            }
            running = true;
        }
        
        public bool draw(Cairo.Context cairo) {
            times += 1.0;
            radius += 0.2;
            for (int i = 0; i < num_of_dots; i++) {
                calc_next_position(i);
                cairo.set_source_rgb(
                    dots[i].color.red,
                    dots[i].color.green,
                    dots[i].color.blue
                );
                cairo.arc(dots[i].x, dots[i].y, radius, 0.0, radians_360_degrees);
                cairo.fill();
            }
            if (times > 20) {
                running = false;
            }
            return false;
        }
        
        private void calc_next_position(int i) {
            dots[i].y = dots[i].initial_y + Math.sin(dots[i].radians) * times;
            dots[i].x = dots[i].initial_x + Math.cos(dots[i].radians) * times;
        }
    }
    
    public class SweeperWidget : Gtk.DrawingArea {
        public signal void started();
        public signal void win();
        public signal void lose(int cell_y, int cell_x);
        
        public bool is_paused {
            get {
                return is_paused_value;
            }
            set {
                is_paused_value = value;
                sensitive = !is_paused_value;
                queue_draw();
            }
        }
        
        public Theme theme {
            get {
                return theme_value;
            }
            set {
                theme_value = value;
                switch (theme_value) {
                  case LIGHT:
                    border_color = { 0.4, 0.4, 0.4, 1.0 };
                    closed_cell_color = { 0.95, 0.95, 0.95, 1.0 };
                    opened_cell_color = { 0.75, 0.75, 0.75, 1.0 };
                    hovered_cell_color = { 0.9, 0.9, 0.5, 1.0 };
                    selected_cell_color = { 1.0, 0.5, 0.2, 1.0 };
                    border_highlight_color = {0.5, 0.8, 0.1, 1.0 };
                    text_color_1 = { 0.1, 0.1, 0.9, 1.0 };
                    text_color_2 = { 0.1, 0.5, 0.0, 1.0 };
                    text_color_3 = { 0.3, 0.3, 0.0, 1.0 };
                    text_color_4 = { 0.5, 0.5, 0.1, 1.0 };
                    text_color_5 = { 0.5, 0.5, 0.1, 1.0 };
                    text_color_6 = { 0.9, 0.1, 0.1, 1.0 };
                    text_color_7 = { 0.9, 0.1, 0.1, 1.0 };
                    bezel_width = 1;
                    cell_width = 20;
                    border_width = 1;
                    break;
                  case DARK:
                    border_color = { 0.15, 0.15, 0.15, 1.0 };
                    closed_cell_color = { 0.25, 0.25, 0.25, 1.0 };
                    opened_cell_color = { 0.1, 0.1, 0.1, 1.0 };
                    hovered_cell_color = { 0.9, 0.9, 0.5, 1.0 };
                    selected_cell_color = { 1.0, 0.5, 0.2, 1.0 };
                    border_highlight_color = {0.5, 0.8, 0.1, 1.0 };
                    text_color_1 = { 0.6, 0.6, 0.9, 1.0 };
                    text_color_2 = { 0.4, 0.8, 0.4, 1.0 };
                    text_color_3 = { 0.8, 0.8, 0.4, 1.0 };
                    text_color_4 = { 0.8, 0.8, 0.4, 1.0 };
                    text_color_5 = { 0.6, 0.6, 0.4, 1.0 };
                    text_color_6 = { 0.9, 0.4, 0.4, 1.0 };
                    text_color_7 = { 0.9, 0.4, 0.4, 1.0 };
                    bezel_width = 0;
                    cell_width = 18;
                    border_width = 3;
                    break;
                }
                queue_draw();
            }
        }
        
        private SweeperModel model;
        private int cell_width = 20;
        private double font_size = 12.0;
        private int border_width = 1;
        private double bezel_width = 1;

        private Gdk.RGBA bomb_color = { 0.0, 0.0, 0.0, 1.0 };
        private Gdk.RGBA mask_color = { 0.0, 0.0, 0.0, 0.3 };
        private Gdk.RGBA text_color_1 = { 0.1, 0.1, 0.9, 1.0 };
        private Gdk.RGBA text_color_2 = { 0.1, 0.5, 0.0, 1.0 };
        private Gdk.RGBA text_color_3 = { 0.3, 0.3, 0.0, 1.0 };
        private Gdk.RGBA text_color_4 = { 0.5, 0.5, 0.1, 1.0 };
        private Gdk.RGBA text_color_5 = { 0.5, 0.5, 0.1, 1.0 };
        private Gdk.RGBA text_color_6 = { 0.9, 0.1, 0.1, 1.0 };
        private Gdk.RGBA text_color_7 = { 0.9, 0.1, 0.1, 1.0 };
        private Cairo.Rectangle[,] rects;
        private Gdk.Point selected_cell;
        private Gdk.Point hovered_cell;
        private double cursor_x;
        private double cursor_y;
        private bool is_paused_value;
        private Theme theme_value;

        private Gdk.RGBA border_color = { 0.6, 0.6, 0.6, 1.0 };
        private Gdk.RGBA closed_cell_color = { 0.95, 0.95, 0.95, 1.0 };
        private Gdk.RGBA opened_cell_color = { 0.75, 0.75, 0.75, 1.0 };
        private Gdk.RGBA hovered_cell_color = { 0.9, 0.9, 0.5, 1.0 };
        private Gdk.RGBA selected_cell_color = { 1.0, 0.5, 0.2, 1.0 };
        private Gdk.RGBA border_highlight_color = { 1.0, 0.5, 0.2, 1.0 };

        private SparkDrawer? spark_drawer = null;
        
        public SweeperWidget.with_model(SweeperModel model) {
            bind_model(model);
        }

        public void bind_model(SweeperModel new_model) {
            model = new_model;
            model.started.connect(() => {
                started();
            });
            model.win.connect(() => {
                win();
            });
            model.lose.connect((cell_y, cell_x) => {
                is_paused = true;
                lose(cell_y, cell_x);
            });
            init();
        }

        public void recover(int cell_y, int cell_x) {
            model.close_cell(cell_y, cell_x);
        }
        
        private void init() {
            selected_cell = { -1, -1 };
            hovered_cell = { -1, -1 };
            rects = new Cairo.Rectangle[model.x_length + 1, model.y_length + 1];
            int[] x = new int[model.x_length + 1];
            int[] y = new int[model.y_length + 1];
            x[0] = border_width;
            for (int i = 0; i < model.x_length; i++) {
                x[i + 1] = x[i] + cell_width + border_width;
            }
            y[0] = border_width;
            for (int i = 0; i < model.y_length; i++) {
                y[i + 1] = y[i] + cell_width + border_width;
            }
            for (int j = 0; j < model.y_length + 1; j++) {
                for (int i = 0; i < model.x_length + 1; i++) {
                    rects[j, i].x = x[i];
                    rects[j, i].width = cell_width;
                    rects[j, i].y = y[j];
                    rects[j, i].height = cell_width;
                }
            }
            add_events (
                Gdk.EventMask.BUTTON_PRESS_MASK |
                Gdk.EventMask.BUTTON_RELEASE_MASK |
                Gdk.EventMask.POINTER_MOTION_MASK |
                Gdk.EventMask.KEY_PRESS_MASK |
                Gdk.EventMask.LEAVE_NOTIFY_MASK
            );
            width_request = (int) rects[0, model.x_length].x;
            height_request = (int) rects[model.y_length, 0].y;
        }
        
        public override bool draw(Cairo.Context cairo) {
            Cairo.TextExtents extents;
            cairo.set_line_width(0.0);
            if (hovered_cell.x >= 0 && hovered_cell.y >= 0) {
                Cairo.Pattern pattern_bg = new Cairo.Pattern.radial(cursor_x, cursor_y, 0,
                        cursor_x, cursor_y, cell_width * 6.0);
                pattern_bg.add_color_stop_rgb(cell_width / 2, border_color.red, border_color.green, border_color.blue);
                pattern_bg.add_color_stop_rgb(0, border_highlight_color.red, border_highlight_color.green, border_highlight_color.blue);
                cairo.set_source(pattern_bg);
            } else {
                cairo.set_source_rgb(border_color.red, border_color.green, border_color.blue);
            }
            cairo.rectangle(
                0,
                0,
                rects[model.x_length, model.y_length].x,
                rects[model.x_length, model.y_length].y
            );
            cairo.fill();
            for (int y = 0; y < model.y_length; y++) {
                for (int x = 0; x < model.x_length; x++) {
                    Gdk.RGBA fill_color = { 0.0, 0.0, 0.0, 0.0 };
                    
                    if (model.is_closed(y, x)) {
                        if (x == selected_cell.x && y == selected_cell.y) {
                            fill_color = selected_cell_color;
                       } else if (x == hovered_cell.x && y == hovered_cell.y) {
                            fill_color = hovered_cell_color;
                        } else {
                            fill_color = closed_cell_color;
                        }

                        if (theme == LIGHT) {
                            double center_x = rects[y, x].x + rects[y, x].width / 2;
                            double center_y = rects[y, x].y + rects[y, x].height / 2;
                            double top_left_x = rects[y, x].x;
                            double top_left_y = rects[y, x].y;
                            double top_right_x = rects[y, x].x + rects[y, x].width;
                            double top_right_y = rects[y, x].y;
                            double bottom_left_x = rects[y, x].x;
                            double bottom_left_y = rects[y, x].y + rects[y, x].height;
                            double bottom_right_x = rects[y, x].x + rects[y, x].width;
                            double bottom_right_y = rects[y, x].y + rects[y, x].height;
                            cairo.set_source_rgb(
                                fill_color.red * 0.5,
                                fill_color.green * 0.5,
                                fill_color.blue * 0.5
                            );
                            cairo.move_to(
                                center_x,
                                center_y
                            );
                            cairo.line_to(
                                bottom_left_x,
                                bottom_left_y
                            );
                            cairo.line_to(
                                bottom_right_x,
                                bottom_right_y
                            );
                            cairo.fill();

                            cairo.set_source_rgb(
                                fill_color.red * 0.75,
                                fill_color.green * 0.75,
                                fill_color.blue * 0.75
                            );
                            cairo.move_to(
                                center_x,
                                center_y
                            );
                            cairo.line_to(
                                top_right_x,
                                top_right_y
                            );
                            cairo.line_to(
                                bottom_right_x,
                                bottom_right_y
                            );
                            cairo.fill();

                            cairo.set_source_rgb(
                                fill_color.red * 1.25,
                                fill_color.green * 1.25,
                                fill_color.blue * 1.25
                            );
                            cairo.move_to(
                                center_x,
                                center_y
                            );
                            cairo.line_to(
                                top_left_x,
                                top_left_y
                            );
                            cairo.line_to(
                                bottom_left_x,
                                bottom_left_y
                            );
                            cairo.fill();

                            cairo.set_source_rgb(
                                fill_color.red * 1.5,
                                fill_color.green * 1.5,
                                fill_color.blue * 1.5
                            );
                            cairo.move_to(
                                center_x,
                                center_y
                            );
                            cairo.line_to(
                                top_left_x,
                                top_left_y
                            );
                            cairo.line_to(
                                top_right_x,
                                top_right_y
                            );
                            cairo.fill();

                            var cell_pattern = new Cairo.Pattern.linear(
                                rects[y, x].x + bezel_width,
                                rects[y, x].y + bezel_width,
                                rects[y, x].x + cell_width - bezel_width * 2,
                                rects[y, x].y + cell_width - bezel_width * 2
                            );

                            cell_pattern.add_color_stop_rgb(
                                0,
                                fill_color.red,
                                fill_color.green,
                                fill_color.blue
                            );

                            cell_pattern.add_color_stop_rgb(
                                rects[y, x].width,
                                fill_color.red * 0.9,
                                fill_color.green * 0.9,
                                fill_color.blue * 0.9
                            );

                            cairo.set_source(cell_pattern);

                        } else {
                            
                            cairo.set_source_rgb(fill_color.red, fill_color.green, fill_color.blue);

                        }
                        
                        cairo.rectangle(
                            rects[y, x].x + bezel_width,
                            rects[y, x].y + bezel_width,
                            cell_width - bezel_width * 2,
                            cell_width - bezel_width * 2
                        );

                        cairo.fill();

                    } else {
                        fill_color = opened_cell_color;

                        cairo.set_source_rgb(
                            fill_color.red,
                            fill_color.green,
                            fill_color.blue
                        );

                        cairo.rectangle(
                            rects[y, x].x,
                            rects[y, x].y,
                            cell_width,
                            cell_width
                        );
                        cairo.fill();
                    }


                    if (!model.is_closed(y, x)) {
                        if (model.has_bomb(y, x)) {
                            cairo.set_source_rgb(bomb_color.red, bomb_color.green, bomb_color.blue);
                            double bomb_x = rects[y, x].x + cell_width / 2;
                            double bomb_y = rects[y, x].y + cell_width / 2;
                            cairo.arc(bomb_x, bomb_y, cell_width / 4, 0.0, 2.0 * Math.PI);
                            cairo.fill();
                        } else {
                            int number = model.get_number(y, x);
                            if (number > 0) {
                                cairo.select_font_face("Sans", NORMAL, BOLD);
                                cairo.set_font_size(font_size);
                                Gdk.RGBA text_color = text_color_1;
                                switch (number) {
                                  case 1:
                                    text_color = text_color_1;
                                    break;
                                  case 2:
                                    text_color = text_color_2;
                                    break;
                                  case 3:
                                    text_color = text_color_3;
                                    break;
                                  case 4:
                                    text_color = text_color_4;
                                    break;
                                  case 5:
                                    text_color = text_color_5;
                                    break;
                                  case 6:
                                    text_color = text_color_6;
                                    break;
                                  case 7:
                                    text_color = text_color_7;
                                    break;
                                }
                                cairo.set_source_rgb(text_color.red, text_color.green, text_color.blue);
                                string number_text = LETTERS[model.get_number(y, x)];
                                cairo.text_extents(number_text, out extents);
                                double text_x = (cell_width / 2) - (extents.width / 2 + extents.x_bearing);
                                double text_y = (cell_width / 2) - (extents.height / 2 + extents.y_bearing);
                                cairo.move_to(
                                    rects[y, x].x + text_x,
                                    rects[y, x].y + text_y
                                );
                                cairo.show_text(number_text);
                            }
                        }
                    } else {
                        if (model.is_fixed(y, x)) {
                            double width = rects[y, x].width;
                            double pole_start_x = width / 4;
                            double pole_start_y = width / 5 * 1;
                            double pole_end_x = width / 4;
                            double pole_end_y = width / 5 * 4;
                            double flag_top_x = width / 4;
                            double flag_top_y = width / 5 * 1;
                            double flag_middle_x = width / 4 * 3;
                            double flag_middle_y = width / 5 * 2;
                            double flag_bottom_x = width / 4;
                            double flag_bottom_y = width / 5 * 3    ;
                            
                            cairo.set_line_width(0.0);
                            cairo.set_source_rgb(0.9, 0.1, 0.1);
                            cairo.move_to(
                                rects[y, x].x + flag_top_x,
                                rects[y, x].y + flag_top_y
                            );
                            cairo.line_to(
                                rects[y, x].x + flag_middle_x,
                                rects[y, x].y + flag_middle_y
                            );
                            cairo.line_to(
                                rects[y, x].x + flag_bottom_x,
                                rects[y, x].y + flag_bottom_y
                            );
                            cairo.fill();

                            cairo.set_source_rgb(0.1, 0.1, 0.1);
                            cairo.set_line_width(2.0);
                            cairo.move_to(
                                rects[y, x].x + pole_start_x,
                                rects[y, x].y + pole_start_y
                            );
                            cairo.line_to(
                                rects[y, x].x + pole_end_x,
                                rects[y, x].y + pole_end_y
                            );
                            cairo.stroke();
                        }
                    }
                }
            }

            if (spark_drawer != null && spark_drawer.running) {
                spark_drawer.draw(cairo);
            }

            if (is_paused) {
                cairo.set_source_rgba(mask_color.red, mask_color.green, mask_color.blue, mask_color.alpha);
                cairo.rectangle(
                    0,
                    0,
                    rects[model.x_length, model.y_length].x,
                    rects[model.x_length, model.y_length].y
                );
                cairo.fill();
            }
            return true;
        }

        public override bool button_press_event(Gdk.EventButton event) {
            int cell_x, cell_y;
            cursor_index((int) event.x, (int) event.y, out cell_x, out cell_y);
            if (event.button == 3) {
                if (!model.is_fixed(cell_y, cell_x)) {
                    model.fix(cell_y, cell_x);
                } else {
                    model.unfix(cell_y, cell_x);
                }
            } else if (!model.is_fixed(cell_y, cell_x)) {
                if (cell_x < 0 || cell_y < 0) {
                    selected_cell.x = -1;
                    selected_cell.y = -1;
                } else if (selected_cell.x == cell_x && selected_cell.y == cell_y) {
                    selected_cell.x = -1;
                    selected_cell.y = -1;
                } else {
                    selected_cell.x = cell_x;
                    selected_cell.y = cell_y;
                }
                bool is_safe = model.open_cell(cell_y, cell_x);
                if (!is_safe) {
                    spark_drawer = new SparkDrawer(
                        rects[cell_y, cell_x].y + cell_width / 2,
                        rects[cell_y, cell_x].x + cell_width / 2
                    );
                    Timeout.add(50, () => {
                        if (spark_drawer.running) {
                            queue_draw();
                            return true;
                        } else {
                            return false;
                        }
                    });
                }
            } else {
                return false;
            }
            queue_draw();
            return true;
        }

        public override bool button_release_event(Gdk.EventButton event) {
            return false;
        }

        public override bool leave_notify_event(Gdk.EventCrossing event) {
            hovered_cell.x = -1;
            hovered_cell.y = -1;
            return false;
        }

        public override bool motion_notify_event(Gdk.EventMotion event) {
            int cell_x, cell_y;
            cursor_index((int) event.x, (int) event.y, out cell_x, out cell_y);
            if (cell_x < 0 || cell_y < 0) {
                hovered_cell.x = -1;
                hovered_cell.y = -1;
            } else {
                hovered_cell.x = cell_x;
                hovered_cell.y = cell_y;
                cursor_x = event.x;
                cursor_y = event.y;
            }
            queue_draw();
            return true;
        }
        
        private void cursor_index(int cursor_x, int cursor_y, out int cell_x, out int cell_y) {
            cell_x = -1;
            cell_y = -1;
            for (int i = 0; i < model.x_length; i++) {
                if (rects[0, i].x <= cursor_x && cursor_x < rects[0, i + 1].x) {
                    cell_x = i;
                }
            }
            for (int j = 0; j < model.y_length; j++) {
                if (rects[j, 0].y <= cursor_y && cursor_y < rects[j + 1, 0].y) {
                    cell_y = j;
                }
            }
        }
    }
}

const int SPACING = 4;

string time_to_string(int milliseconds) {
    int deciseconds = milliseconds % 1000 / 100;
    int minutes = milliseconds / 1000 / 60;
    int seconds = milliseconds / 1000 % 60;
    return "%02d:%02d.%d".printf(minutes, seconds, deciseconds);
}

int main(string[] argv) {
    var app = new Gtk.Application("com.github.aharotias2.aho-sweeper", FLAGS_NONE);
    app.activate.connect(() => {
        int playing_time = 0;
        bool game_playing = false;
        Gtk.Label? time_label = null;
        Gtk.ComboBoxText? size_selector = null;
        Aho.SweeperWidget? sweeper = null;
        
        var window = new Gtk.ApplicationWindow(app);
        {
            var headerbar = new Gtk.HeaderBar();
            {
                var theme_switch = new Gtk.Switch();
                theme_switch.state_set.connect(() => {
                    if (theme_switch.active) {
                        sweeper.theme = Aho.Theme.DARK;
                    } else {
                        sweeper.theme = Aho.Theme.LIGHT;
                    }
                    var gtk_settings = Gtk.Settings.get_default();
                    if (sweeper.theme == DARK) {
                        gtk_settings.gtk_application_prefer_dark_theme = true;
                    } else {
                        gtk_settings.gtk_application_prefer_dark_theme = false;
                    }
                    return true;
                });
                
                headerbar.pack_start(theme_switch);
                headerbar.show_close_button = true;
            }
            
            var box_1 = new Gtk.Box(VERTICAL, SPACING);
            {
                var box_2 = new Gtk.Box(HORIZONTAL, SPACING);
                {
                    size_selector = new Gtk.ComboBoxText();
                    {
                        foreach (var size in Aho.ModelSize.all()) {
                            size_selector.append(size.to_string(), size.to_string());
                        }
                        size_selector.changed.connect(() => {
                            if (sweeper != null) {
                                var size = Aho.ModelSize.from_string(size_selector.active_id);
                                sweeper.bind_model(new Aho.SweeperModel(size));
                                playing_time = 0;
                                time_label.label = time_to_string(playing_time);
                                game_playing = false;
                                sweeper.is_paused = false;
                            }
                        });
                        size_selector.active_id = "16x16";
                    }
                    
                    var reset_button = new Gtk.Button.with_label("Reset");
                    {
                        reset_button.clicked.connect(() => {
                            var size = Aho.ModelSize.from_string(size_selector.active_id);
                            sweeper.bind_model(new Aho.SweeperModel(size));
                            playing_time = 0;
                            time_label.label = time_to_string(playing_time);
                            game_playing = false;
                            sweeper.is_paused = false;
                        });
                    }
                    
                    var rule_button = new Gtk.Button.from_icon_name("help-browser");
                    {
                        rule_button.clicked.connect(() => {
                            var dialog = new Gtk.MessageDialog(
                                    window, MODAL, INFO, OK, Aho.RULE_DESCRIPTION);
                            dialog.run();
                            dialog.close();
                        });
                    }
                    
                    time_label = new Gtk.Label(time_to_string(playing_time));
                    
                    box_2.pack_start(size_selector, false, false);
                    box_2.pack_start(reset_button, false, false);
                    box_2.pack_start(rule_button, false, false);
                    box_2.pack_end(time_label, false, false);
                }
                
                sweeper = new Aho.SweeperWidget.with_model(new Aho.SweeperModel(Aho.ModelSize.MODEL_16X16));
                {
                    sweeper.started.connect(() => {
                        playing_time = 0;
                        game_playing = true;
                        Timeout.add(100, () => {
                            if (game_playing) {
                                playing_time += 100;
                                time_label.label = time_to_string(playing_time);
                                return true;
                            } else {
                                return false;
                            }
                        });
                    });
                    sweeper.win.connect(() => {
                        game_playing = false;
                        sweeper.is_paused = true;
                        Timeout.add(500, () => {
                            var dialog = new Gtk.MessageDialog(
                                    window, MODAL, INFO, YES_NO, "おめでとうございます!!!!!\n\nあなたの勝ちです!!!!!!!\n\nこの度のあなたの勝利を大変喜ばしく存じます。\n\n本当に、本当によかったです!!!!\n\n続けてプレイしますか？");
                            int response_id = dialog.run();
                            if (response_id == Gtk.ResponseType.YES) {
                                Idle.add(() => {
                                    var size = Aho.ModelSize.from_string(size_selector.active_id);
                                    sweeper.bind_model(new Aho.SweeperModel(size));
                                    sweeper.is_paused = false;
                                    return false;
                                });
                            }
                            dialog.close();
                            return false;
                        });
                    });
                    sweeper.lose.connect((cell_y, cell_x) => {
                        game_playing = false;
                        Timeout.add(1000, () => {
                            var dialog = new Gtk.MessageDialog(
                                    window, MODAL, INFO, YES_NO, "残念ですが、あなたの負けです!!!!!!!!\n\nしかし、これで全てが終わったわけではありません……\n\nあなたは次こそは必ずや勝利を収めるでしょう!!!!!\n\n諦めなければ、いつかきっと勝てます!!!!\n\n途中からやり直しますか？");
                            dialog.set_default_response(Gtk.ResponseType.YES);
                            int response_id = dialog.run();
                            if (response_id == Gtk.ResponseType.YES) {
                                Idle.add(() => {
                                    sweeper.recover(cell_y, cell_x);
                                    sweeper.is_paused = false;
                                    return false;
                                });
                            } else {
                                Idle.add(() => {
                                    var size = Aho.ModelSize.from_string(size_selector.active_id);
                                    sweeper.bind_model(new Aho.SweeperModel(size));
                                    sweeper.is_paused = false;
                                    return false;
                                });
                            }
                            dialog.close();
                            return false;
                        });
                    });
                }
                box_1.pack_start(box_2, false, false);
                box_1.pack_start(sweeper, false, false);
                box_1.margin = SPACING;
            }
            window.set_titlebar(headerbar);
            window.add(box_1);
            window.title = "Let's Sweep!";
        }
        window.show_all();
    });
    return app.run(argv);
}
