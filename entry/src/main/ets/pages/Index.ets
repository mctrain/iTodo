import preferences from '@ohos.data.preferences';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import type common from '@ohos.app.ability.common';

interface TodoItemLike {
  id: string;
  text: string;
  completed: boolean;
  createdAt: number;
}

interface TodoEntryLike {
  date: string;
  items: Array<TodoItemLike>;
}

class TodoItem {
  id: string;
  text: string;
  completed: boolean;
  createdAt: number;

  constructor(id: string, text: string, completed: boolean, createdAt: number) {
    this.id = id;
    this.text = text;
    this.completed = completed;
    this.createdAt = createdAt;
  }
}

class TodoEntry {
  date: string;
  items: Array<TodoItem>;

  constructor(date: string, items: Array<TodoItem>) {
    this.date = date;
    this.items = items;
  }
}

class Theme {
  name: string;
  background: string;
  card: string;
  accent: string;
  text: string;
  subText: string;
  chip: string;

  constructor(name: string, background: string, card: string, accent: string, text: string, subText: string, chip: string) {
    this.name = name;
    this.background = background;
    this.card = card;
    this.accent = accent;
    this.text = text;
    this.subText = subText;
    this.chip = chip;
  }
}

class CalendarDay {
  label: string;
  dateStr: string;
  isCurrentMonth: boolean;

  constructor(label: string, dateStr: string, isCurrentMonth: boolean) {
    this.label = label;
    this.dateStr = dateStr;
    this.isCurrentMonth = isCurrentMonth;
  }
}

const WEEK_LABELS: Array<string> = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

const THEMES: Theme[] = [
  new Theme('Lavender', '#F3ECFF', '#FFFFFF', '#7E57C2', '#1F1B2E', '#6B6485', '#E7D9FF'),
  new Theme('Cyber', '#0B0B1E', '#1C1230', '#00F0FF', '#F3F1FF', '#9C8CD7', '#251C3D'),
  new Theme('Forest', '#EAF7EC', '#FFFFFF', '#2E7D32', '#1B2E1E', '#5C7C62', '#D7EEDB'),
  new Theme('Sunset', '#FFF1E6', '#FFFFFF', '#F97316', '#3A1C10', '#8A5640', '#FFE1CC'),
  new Theme('Ocean', '#E7F6FF', '#FFFFFF', '#0284C7', '#0B2238', '#4D6A82', '#D6EEFF'),
  new Theme('Minimal', '#F6F6F6', '#FFFFFF', '#111827', '#111827', '#6B7280', '#E5E7EB')
];

@CustomDialog
struct ExportDialog {
  controller: CustomDialogController;
  text: string = '';
  onCopy: () => void = () => {};
  onClose: () => void = () => {};

  build(): void {
    Column({ space: 12 }) {
      Text('Export Data')
        .fontSize(18)
        .fontWeight(FontWeight.Medium);
      TextArea({ text: this.text })
        .height(180)
        .borderRadius(12)
        .fontSize(12)
        .backgroundColor('#F3F4F6');
      Row({ space: 12 }) {
        Button('Copy')
          .backgroundColor('#111827')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.onCopy();
          });
        Button('Close')
          .backgroundColor('#E5E7EB')
          .fontColor('#111827')
          .onClick(() => {
            this.onClose();
          });
      }
      .justifyContent(FlexAlign.End)
      .width('100%');
    }
    .padding(20)
    .borderRadius(16)
    .backgroundColor('#FFFFFF');
  }
}

@CustomDialog
struct ImportDialog {
  controller: CustomDialogController;
  initialText: string = '';
  onImport: (value: string) => void = (_value: string) => {};
  onClose: () => void = () => {};
  @State text: string = '';

  aboutToAppear(): void {
    this.text = this.initialText;
  }

  build(): void {
    Column({ space: 12 }) {
      Text('Import Data')
        .fontSize(18)
        .fontWeight(FontWeight.Medium);
      TextArea({ text: this.text, placeholder: 'Paste JSON backup' })
        .height(180)
        .borderRadius(12)
        .fontSize(12)
        .backgroundColor('#F3F4F6')
        .onChange((value: string) => {
          this.text = value;
        });
      Row({ space: 12 }) {
        Button('Import')
          .backgroundColor('#111827')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.onImport(this.text);
          });
        Button('Cancel')
          .backgroundColor('#E5E7EB')
          .fontColor('#111827')
          .onClick(() => {
            this.onClose();
          });
      }
      .justifyContent(FlexAlign.End)
      .width('100%');
    }
    .padding(20)
    .borderRadius(16)
    .backgroundColor('#FFFFFF');
  }
}

@Entry
@Component
struct Index {
  @State todos: Array<TodoEntry> = [];
  @State selectedDate: string = '';
  @State currentMonth: number = 0;
  @State currentYear: number = 0;
  @State newTodoText: string = '';
  @State themeName: string = THEMES[0].name;
  @State exportText: string = '';

  private pref?: preferences.Preferences;
  private exportDialogController: CustomDialogController = new CustomDialogController({
    builder: () => {
      ExportDialog({
        controller: this.exportDialogController,
        text: this.exportText,
        onCopy: () => {
          this.copyExport();
        },
        onClose: () => {
          this.exportDialogController.close();
        }
      });
    },
    autoCancel: true
  });
  private importDialogController: CustomDialogController = new CustomDialogController({
    builder: () => {
      ImportDialog({
        controller: this.importDialogController,
        initialText: '',
        onImport: (value: string) => {
          this.handleImport(value);
        },
        onClose: () => {
          this.importDialogController.close();
        }
      });
    },
    autoCancel: true
  });

  aboutToAppear(): void {
    const now = new Date();
    this.currentMonth = now.getMonth();
    this.currentYear = now.getFullYear();
    this.selectedDate = this.formatDate(now);
    this.loadPreferences();
  }

  private pad2(value: number): string {
    if (value < 10) {
      return '0' + value;
    }
    return '' + value;
  }

  private async loadPreferences(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.pref = await preferences.getPreferences(context, 'coolTodoPrefs');
      const todoJson = (await this.pref.get('coolTodosCalendar', '{}')) as string;
      const theme = (await this.pref.get('todoTheme', THEMES[0].name)) as string;
      const entries = this.parseImport(todoJson);
      if (entries !== undefined) {
        this.todos = entries;
      }
      this.themeName = theme;
    } catch (err) {
      promptAction.showToast({ message: 'Failed to load local data, using defaults.' });
    }
  }

  private async saveTodos(): Promise<void> {
    if (!this.pref) {
      return;
    }
    await this.pref.put('coolTodosCalendar', this.buildExportJson());
    await this.pref.flush();
  }

  private async saveTheme(): Promise<void> {
    if (!this.pref) {
      return;
    }
    await this.pref.put('todoTheme', this.themeName);
    await this.pref.flush();
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = this.pad2(date.getMonth() + 1);
    const day = this.pad2(date.getDate());
    return year + '-' + month + '-' + day;
  }

  private buildCalendarDays(): Array<CalendarDay> {
    const firstDay = new Date(this.currentYear, this.currentMonth, 1);
    const startWeekday = firstDay.getDay();
    const daysInMonth = new Date(this.currentYear, this.currentMonth + 1, 0).getDate();
    const daysInPrevMonth = new Date(this.currentYear, this.currentMonth, 0).getDate();
    const list: Array<CalendarDay> = [];

    let i = startWeekday - 1;
    while (i >= 0) {
      const day = daysInPrevMonth - i;
      const date = new Date(this.currentYear, this.currentMonth - 1, day);
      list.push(new CalendarDay('' + day, this.formatDate(date), false));
      i -= 1;
    }

    let day = 1;
    while (day <= daysInMonth) {
      const date = new Date(this.currentYear, this.currentMonth, day);
      list.push(new CalendarDay('' + day, this.formatDate(date), true));
      day += 1;
    }

    const remaining = 42 - list.length;
    day = 1;
    while (day <= remaining) {
      const date = new Date(this.currentYear, this.currentMonth + 1, day);
      list.push(new CalendarDay('' + day, this.formatDate(date), false));
      day += 1;
    }

    return list;
  }

  private getTheme(): Theme {
    let selected = THEMES[0];
    let i = 0;
    while (i < THEMES.length) {
      if (THEMES[i].name === this.themeName) {
        selected = THEMES[i];
        break;
      }
      i += 1;
    }
    return selected;
  }

  private findEntry(dateStr: string): TodoEntry | undefined {
    let i = 0;
    while (i < this.todos.length) {
      const entry = this.todos[i];
      if (entry.date === dateStr) {
        return entry;
      }
      i += 1;
    }
    return undefined;
  }

  private getTodosByDate(dateStr: string): Array<TodoItem> {
    const entry = this.findEntry(dateStr);
    if (entry === undefined) {
      return [];
    }
    return entry.items;
  }

  private getTodoCount(dateStr: string): number {
    const entry = this.findEntry(dateStr);
    if (entry === undefined) {
      return 0;
    }
    return entry.items.length;
  }

  private updateTodos(dateStr: string, items: Array<TodoItem>): void {
    const newTodos: Array<TodoEntry> = [];
    let replaced = false;
    this.todos.forEach((entry: TodoEntry) => {
      if (entry.date === dateStr) {
        newTodos.push(new TodoEntry(dateStr, items));
        replaced = true;
      } else {
        newTodos.push(entry);
      }
    });
    if (!replaced) {
      newTodos.push(new TodoEntry(dateStr, items));
    }
    this.todos = newTodos;
    this.saveTodos();
  }

  private addTodo(): void {
    const text = this.newTodoText.trim();
    if (!text) {
      promptAction.showToast({ message: 'Please enter a todo.' });
      return;
    }
    const dateStr = this.selectedDate;
    const list = this.getTodosByDate(dateStr);
    const now = Date.now();
    const item = new TodoItem('' + now, text, false, now);
    const newList: Array<TodoItem> = [item];
    list.forEach((existing: TodoItem) => {
      newList.push(existing);
    });
    this.updateTodos(dateStr, newList);
    this.newTodoText = '';
  }

  private toggleTodo(dateStr: string, id: string): void {
    const list = this.getTodosByDate(dateStr);
    const updated: Array<TodoItem> = [];
    list.forEach((item: TodoItem) => {
      if (item.id === id) {
        updated.push(new TodoItem(item.id, item.text, !item.completed, item.createdAt));
      } else {
        updated.push(item);
      }
    });
    this.updateTodos(dateStr, updated);
  }

  private removeTodo(dateStr: string, id: string): void {
    const list = this.getTodosByDate(dateStr);
    const updated: Array<TodoItem> = [];
    list.forEach((item: TodoItem) => {
      if (item.id !== id) {
        updated.push(item);
      }
    });
    this.updateTodos(dateStr, updated);
  }

  private changeMonth(offset: number): void {
    const date = new Date(this.currentYear, this.currentMonth + offset, 1);
    this.currentYear = date.getFullYear();
    this.currentMonth = date.getMonth();
  }

  private getMonthLabel(): string {
    return this.currentYear + '-' + (this.currentMonth + 1);
  }

  private getTodayStr(): string {
    return this.formatDate(new Date());
  }

  private isThemeActive(name: string): boolean {
    return name === this.themeName;
  }

  private isSelectedDate(dateStr: string): boolean {
    return dateStr === this.selectedDate;
  }

  private isToday(dateStr: string): boolean {
    return dateStr === this.getTodayStr();
  }

  private buildExportJson(): string {
    let json = '{';
    let first = true;
    this.todos.forEach((entry: TodoEntry) => {
      if (!first) {
        json = json + ',';
      }
      json = json + '"' + entry.date + '":' + JSON.stringify(entry.items);
      first = false;
    });
    json = json + '}';
    return json;
  }

  private copyExport(): void {
    try {
      const systemPaste = pasteboard.getSystemPasteboard();
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.exportText);
      systemPaste.setData(data).then(() => {
        promptAction.showToast({ message: 'Copied to clipboard.' });
      }).catch(() => {
        promptAction.showToast({ message: 'Copy failed, please copy manually.' });
      });
    } catch (err) {
      promptAction.showToast({ message: 'Copy failed, please copy manually.' });
    }
  }

  private showExportDialog(): void {
    this.exportText = this.buildExportJson();
    this.exportDialogController.open();
  }

  private showImportDialog(): void {
    this.importDialogController.open();
  }

  private normalizeItems(rawItems: Array<Object>): Array<TodoItem> {
    const items: Array<TodoItem> = [];
    rawItems.forEach((raw: Object) => {
      const item = raw as TodoItemLike;
      items.push(new TodoItem(item.id, item.text, item.completed, item.createdAt));
    });
    return items;
  }

  private parseImport(value: string): Array<TodoEntry> | undefined {
    const parsed: Object = JSON.parse(value) as Object;
    if (parsed === null || typeof parsed !== 'object') {
      return undefined;
    }
    const results: Array<TodoEntry> = [];
    if (Array.isArray(parsed)) {
      (parsed as Array<TodoEntryLike>).forEach((entry: TodoEntryLike) => {
        const items = this.normalizeItems(entry.items as Array<Object>);
        results.push(new TodoEntry(entry.date, items));
      });
      return results;
    }
    const rawEntries = Object.entries(parsed) as Array<Array<Object>>;
    let i = 0;
    while (i < rawEntries.length) {
      const pair = rawEntries[i];
      const key = pair[0] as string;
      const valueObj = pair[1] as Object;
      if (Array.isArray(valueObj)) {
        const items = this.normalizeItems(valueObj as Array<Object>);
        results.push(new TodoEntry(key, items));
      }
      i += 1;
    }
    return results;
  }

  private handleImport(value: string): void {
    try {
      const entries = this.parseImport(value);
      if (entries === undefined) {
        throw new Error('Invalid');
      }
      this.todos = entries;
      this.saveTodos();
      this.importDialogController.close();
      promptAction.showToast({ message: 'Import successful.' });
    } catch (err) {
      promptAction.showToast({ message: 'Invalid JSON, please check content.' });
    }
  }

  build(): void {
    Column({ space: 16 }) {
      Column({ space: 8 }) {
        Row({ space: 10 }) {
          Image($r('app.media.logo'))
            .width(36)
            .height(36)
            .objectFit(ImageFit.Contain);
          Text('iTodo')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTheme().text);
        }
        Text('Calendar Tasks')
          .fontSize(14)
          .fontColor(this.getTheme().subText);
      }
      .padding({ left: 20, right: 20, top: 24 });

      Row({ space: 12 }) {
        Button('<')
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(this.getTheme().chip)
          .fontColor(this.getTheme().text)
          .onClick(() => {
            this.changeMonth(-1);
          });
        Text(this.getMonthLabel())
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTheme().text)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
        Button('>')
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(this.getTheme().chip)
          .fontColor(this.getTheme().text)
          .onClick(() => {
            this.changeMonth(1);
          });
      }
      .padding({ left: 20, right: 20 });

      Scroll() {
        Row({ space: 10 }) {
          ForEach(THEMES, (themeOption: Theme) => {
            Button(themeOption.name)
              .height(36)
              .padding({ left: 14, right: 14 })
              .borderRadius(18)
              .backgroundColor(this.isThemeActive(themeOption.name) ? themeOption.accent : themeOption.chip)
              .fontColor(this.isThemeActive(themeOption.name) ? '#FFFFFF' : themeOption.text)
              .onClick(() => {
                this.themeName = themeOption.name;
                this.saveTheme();
              });
          });
        }
        .padding({ left: 20, right: 20, top: 6, bottom: 6 });
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off);

      Column({ space: 12 }) {
        Row() {
          ForEach(WEEK_LABELS, (label: string) => {
            Text(label)
              .fontSize(12)
              .fontColor(this.getTheme().subText)
              .width('14.28%')
              .textAlign(TextAlign.Center);
          });
        }

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.buildCalendarDays(), (dayInfo: CalendarDay) => {
            Column() {
              Text(dayInfo.label)
                .fontSize(14)
                .fontColor(dayInfo.isCurrentMonth ? this.getTheme().text : this.getTheme().subText)
                .fontWeight(this.isSelectedDate(dayInfo.dateStr) ? FontWeight.Medium : FontWeight.Regular)
                .textAlign(TextAlign.Center)
                .padding({ top: 10, bottom: 6 });
              if (this.getTodoCount(dayInfo.dateStr) > 0) {
                Row()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(this.getTheme().accent)
                  .margin({ bottom: 6 });
              } else {
                Row()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor('transparent')
                  .margin({ bottom: 6 });
              }
            }
            .width('14.28%')
            .height(62)
            .borderRadius(14)
            .backgroundColor(this.isSelectedDate(dayInfo.dateStr) ? this.getTheme().accent : 'transparent')
            .onClick(() => {
              this.selectedDate = dayInfo.dateStr;
              if (!dayInfo.isCurrentMonth) {
                const date = new Date(dayInfo.dateStr);
                this.currentYear = date.getFullYear();
                this.currentMonth = date.getMonth();
              }
            })
            .padding({ bottom: 6 })
            .opacity(dayInfo.isCurrentMonth ? 1 : 0.45)
            .border({ width: this.isToday(dayInfo.dateStr) ? 1 : 0, color: this.getTheme().accent });
          });
        }
      }
      .padding({ left: 16, right: 16, top: 12 })
      .backgroundColor(this.getTheme().card)
      .borderRadius(24)
      .margin({ left: 20, right: 20 })
      .shadow({ radius: 12, color: '#00000014', offsetX: 0, offsetY: 6 });

      Column({ space: 12 }) {
        Row() {
          Text('Todos - ' + this.selectedDate)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getTheme().text)
            .layoutWeight(1);
          Button('Export')
            .height(30)
            .padding({ left: 10, right: 10 })
            .borderRadius(16)
            .backgroundColor(this.getTheme().chip)
            .fontColor(this.getTheme().text)
            .onClick(() => {
              this.showExportDialog();
            });
          Button('Import')
            .height(30)
            .padding({ left: 10, right: 10 })
            .borderRadius(16)
            .backgroundColor(this.getTheme().chip)
            .fontColor(this.getTheme().text)
            .onClick(() => {
              this.showImportDialog();
            });
        }

        Row({ space: 10 }) {
          TextInput({ text: this.newTodoText, placeholder: 'Add a new todo' })
            .layoutWeight(1)
            .height(40)
            .backgroundColor('#F3F4F6')
            .borderRadius(12)
            .padding({ left: 12 })
            .onChange((value: string) => {
              this.newTodoText = value;
            });
          Button('Add')
            .height(40)
            .padding({ left: 16, right: 16 })
            .borderRadius(12)
            .backgroundColor(this.getTheme().accent)
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.addTodo();
            });
        }

        if (this.getTodosByDate(this.selectedDate).length === 0) {
          Text('No tasks for this date')
            .fontSize(13)
            .fontColor(this.getTheme().subText)
            .padding({ top: 12 });
        } else {
          Column({ space: 10 }) {
            ForEach(this.getTodosByDate(this.selectedDate), (item: TodoItem) => {
              Row({ space: 10 }) {
                Button(item.completed ? 'Done' : 'Complete')
                  .height(28)
                  .padding({ left: 10, right: 10 })
                  .borderRadius(14)
                  .backgroundColor(item.completed ? '#DCFCE7' : this.getTheme().chip)
                  .fontColor(item.completed ? '#166534' : this.getTheme().text)
                  .onClick(() => {
                    this.toggleTodo(this.selectedDate, item.id);
                  });
                Text(item.text)
                  .fontSize(14)
                  .fontColor(item.completed ? this.getTheme().subText : this.getTheme().text)
                  .decoration({
                    type: item.completed ? TextDecorationType.LineThrough : TextDecorationType.None
                  })
                  .layoutWeight(1);
                Button('Delete')
                  .height(28)
                  .padding({ left: 10, right: 10 })
                  .borderRadius(14)
                  .backgroundColor('#FEE2E2')
                  .fontColor('#991B1B')
                  .onClick(() => {
                    this.removeTodo(this.selectedDate, item.id);
                  });
              }
              .padding(12)
              .backgroundColor(this.getTheme().card)
              .borderRadius(16)
              .shadow({ radius: 8, color: '#0000000F', offsetX: 0, offsetY: 4 });
            });
          }
        }
      }
      .padding({ left: 20, right: 20, top: 16, bottom: 24 })
      .backgroundColor(this.getTheme().background)
      .borderRadius(24)
      .margin({ left: 20, right: 20, bottom: 24 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getTheme().background);
  }
}



