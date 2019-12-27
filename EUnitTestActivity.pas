﻿namespace com.eunit.android;

interface

uses
  java.util,
  android.app,
  android.content,
  android.os,
  android.util,
  android.view,
  android.widget,
  android.graphics,
  android.graphics.drawable,
  remobjects.elements.eunit;

type
  EUnitTestActivity = public class(Activity)
  private
    var rootView: LinearLayout;
    method BuildUI: View;

  public
    class var listener: ListViewTestListener;
    var testsAdapter: TestAdapter;
    var listView: ListView;

    method onCreate(savedInstanceState: Bundle); override;
  end;

  ListViewTestListener = public class(IEventListener, IEventListenerGUI)
  public
    var tests := new ArrayList<ITest>();
    var testResults := new HashMap<String, ITestResult>();
    var runningTest: nullable ITest;

    var hostActivity: EUnitTestActivity;
    var testHandler := new TestHandler(Looper.getMainLooper);

    method RunStarted(Test: ITest); virtual;
    method TestStarted(Test: ITest); virtual;
    method TestFinished(TestResult: ITestResult); virtual;
    method RunFinished(TestResult: ITestResult); virtual;

    method PrepareGUI;
    method RunGUI;
    method FinishGUI;
  end;

  TestHandler = class(Handler)
  public
    method handleMessage(msg: Message); override;
  end;

  MsgType = private enum(
    RunStarted,
    TestStarted,
    TestFinished,
    RunFinished
  ) of Integer;

  TestAdapter = class(BaseAdapter)
  private
    const kBlueColor = Color.parseColor('#D9D9FF');
    const kRedColor = Color.parseColor('#FFD9D9');
    const kGreenColor = Color.parseColor('#D9FFD9');
    const kYellowColor = Color.parseColor('#FFFFD9');
    const kWhiteColor = Color.parseColor('#FFFFFF');

    const kRowNameId = 40000;
    const kRowDetailId = 40001;

    var context: Context;
    method CreateRow(ctx: Context): View;

  public
    constructor(ctx: Context);
    method getView(position: Integer; convertView: View; parent: ViewGroup): View; override;
    method getCount: Integer; override;
    method getItem(position: Integer): ITest; override;
    method getItemId(position: Integer): Int64; override;
  end;

  TestRowViewHolder nested in TestAdapter = unit class
  public
    var rowView: View;
    var nameTextView: TextView;
    var detailTextView: TextView;
  end;

implementation

method EUnitTestActivity.onCreate(savedInstanceState: Bundle);
begin
  inherited;
  ContentView := BuildUI();

  listener := new ListViewTestListener();
  listener.hostActivity := self;

  var lTests := Discovery.DiscoverTests(self);
  Runner.RunTests(lTests) withListener(listener);
end;

method EUnitTestActivity.BuildUI: View;
begin
  rootView := new LinearLayout(self);
  rootView.Orientation := LinearLayout.VERTICAL;

  Title := 'EUnit';

  { Set up List view }
  testsAdapter := new TestAdapter(self);
  listView := new ListView(self);
  listView.LayoutParams := new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT);
  listView.setDivider(new ColorDrawable(Color.parseColor('#BBBBBB')));
  listView.setDividerHeight(2);
  listView.Adapter := testsAdapter;

  { Add views to root }
  rootView.addView(listView);

  exit rootView;
end;

method ListViewTestListener.RunStarted(Test: ITest);
begin
  testHandler.sendEmptyMessage(Integer(MsgType.RunStarted));
end;

method ListViewTestListener.TestStarted(Test: ITest);
begin
  testHandler.sendMessage(testHandler.obtainMessage(Integer(MsgType.TestStarted), Test));
end;

method ListViewTestListener.TestFinished(TestResult: ITestResult);
begin

  testHandler.sendMessage(testHandler.obtainMessage(Integer(MsgType.TestFinished), TestResult));
end;

method ListViewTestListener.RunFinished(TestResult: ITestResult);
begin
end;

method ListViewTestListener.PrepareGUI;
begin
end;

method ListViewTestListener.RunGUI;
begin
end;

method ListViewTestListener.FinishGUI;
begin
  testHandler.sendEmptyMessage(Integer(MsgType.RunFinished));
end;

method TestHandler.handleMessage(msg: Message);
begin
  case (msg.what as MsgType) of
    MsgType.RunStarted: begin
        EUnitTestActivity.listener.hostActivity.Title := 'EUnit — Running Tests';
      end;
    MsgType.TestStarted: begin
        var test := ITest(msg.obj);
        EUnitTestActivity.listener.runningTest := test;
        EUnitTestActivity.listener.tests.add(test);
        EUnitTestActivity.listener.hostActivity.testsAdapter.notifyDataSetChanged();
      end;
    MsgType.TestFinished: begin
        var testResult := ITestResult(msg.obj);
        EUnitTestActivity.listener.testResults.put(testResult.Id, testResult);
        EUnitTestActivity.listener.hostActivity.testsAdapter.notifyDataSetChanged();
      end;
    MsgType.RunFinished: begin
        EUnitTestActivity.listener.runningTest := nil;
        EUnitTestActivity.listener.hostActivity.testsAdapter.notifyDataSetChanged();
        EUnitTestActivity.listener.hostActivity.listView.invalidate();
        EUnitTestActivity.listener.hostActivity.Title := 'EUnit — Done';
      end;
  end;
end;

constructor TestAdapter(ctx: Context);
begin
  context := ctx;
end;

method TestAdapter.getView(position: Integer; convertView: View; parent: ViewGroup): View;
begin
  var holder: TestRowViewHolder;

  if convertView = nil then
  begin
    convertView := CreateRow(context);
    holder := new TestRowViewHolder;
    holder.rowView := convertView;
    holder.nameTextView := TextView(convertView.findViewById(kRowNameId));
    holder.detailTextView := TextView(convertView.findViewById(kRowDetailId));
    convertView.Tag := holder;
  end
  else
    holder := TestRowViewHolder(convertView.Tag);

  var lTest := EUnitTestActivity.listener.tests[position];

  holder.nameTextView:Text := lTest.Name;
  if lTest = EUnitTestActivity.listener.runningTest then begin
    holder.detailTextView:Text := 'Testing...';
    holder.rowView.BackgroundColor := kBlueColor;
  end
  else begin
    var lTestResult := EUnitTestActivity.listener.testResults[lTest.Id];
    if assigned(lTestResult) then begin
      case lTestResult.State of
        TestState.Failed: begin
            holder.detailTextView:Text := 'Failed';
            holder.rowView.BackgroundColor := kRedColor;
          end;
        TestState.Skipped: begin
            holder.detailTextView:Text := 'Skipped';
            holder.rowView.BackgroundColor := kYellowColor;
          end;
        TestState.Succeeded: begin
            holder.detailTextView:Text := 'Succeeded';
            holder.rowView.BackgroundColor := kGreenColor;
          end;
        TestState.Untested: begin
            holder.detailTextView:Text := 'Untested';
            holder.rowView.BackgroundColor := kWhiteColor;
          end;
      end;
    end
    else begin
      holder.detailTextView:Text := 'Unknown';
      holder.rowView.BackgroundColor := kWhiteColor;
    end;
  end;

  exit convertView;
end;

method TestAdapter.getCount: Integer;
begin
  exit EUnitTestActivity.listener:tests:size;
end;

method TestAdapter.getItem(position: Integer): ITest;
begin
  if position < EUnitTestActivity.listener.tests.size then
    exit EUnitTestActivity.listener.tests[position];
  exit nil;
end;

method TestAdapter.getItemId(position: Integer): Int64;
begin
  exit position;
end;

method TestAdapter.CreateRow(ctx: Context): View;
begin
  var row := new RelativeLayout(ctx);
  row.LayoutParams := new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);

  var lp := new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);

  var nameView := new TextView(ctx);
  nameView.Id := kRowNameId;
  lp.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
  nameView.LayoutParams := lp;
  nameView.setPadding(36, 36, 36, 36);
  nameView.TextSize := 18;
  nameView.TextColor := Color.BLACK;

  lp := new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);

  var detailView := new TextView(ctx);
  detailView.Id := kRowDetailId;
  lp.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
  detailView.LayoutParams := lp;
  detailView.setPadding(36, 36, 36, 36);
  detailView.TextSize := 18;
  detailView.TextColor := Color.GRAY;

  row.addView(nameView);
  row.addView(detailView);

  exit row;
end;

end.