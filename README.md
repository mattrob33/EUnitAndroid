# EUnitAndroid
An Android UI for displaying [EUnit](https://github.com/remobjects/EUnit) test results, similar to [TableViewTestListener](https://github.com/remobjects/EUnit/blob/master/Sources/iOS/TableViewTestListener.pas) for iOS.

To use EUnitTestActivity in your project, simply create an Android EUnit Test Application project and extend EUnitTestActivity instead of extending Activity. For example,
```
MainActivity = public class(Activity)
end;
```
becomes
```
MainActivity = public class(EUnitTestActivity)
end;
```

### Note
EUnitTestActivity is designed to be as lightweight as possible. To this end, it extends Activity rather than AppCompatActivity and uses ListView instead of RecyclerView, so as to avoid importing the Android support library. (The use of ListView does follow best practices with convertView and the ViewHolder pattern, so there is no noticeable performance hit). If you prefer to use the support library equivalents, simply include the support library as a project reference and modify EUnitTestActivity to extend AppCompatActivity.
