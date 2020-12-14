<div id="longDesc">

# Introduction

This project will give you crash course on WPF MVVM that you can do in your lunch break! Everything you need to know about binding, INotifyPropertyChanged, Dependency Objects & Properites, POCO objects, Business Objects, Attached Properties and much more!

For a full discussion and detailed breakdown of this project, please read below:

<span style="font-size:small">**[http://social.technet.microsoft.com/wiki/contents/articles/13536.easy-mvvm-examples.aspx](http://social.technet.microsoft.com/wiki/contents/articles/13536.easy-mvvm-examples.aspx)**</span>

# <span>Building the Sample</span>

Just download, unzip, open and run!

# <span style="font-size:20px">Description</span>

This project consists of five windows, with practicly no code behind.

All application functionality and navigation is done by the ViewModels

## **MainWindow - Classic INotifyPropertyChanged**

![](http://i1.gallery.technet.s-msft.com/easy-mvvm-examples-48c94de3/image/file/66211/1/mvvm1.png)

This is the classic MVVM configuration, implementing INotifyPropertyChanged in a base class (ViewModelBase)

The ViewModel is attached by the View itself, in XAML. This is fine if the ViewModel constructor has no parameters.

It has a ListBox, DataGrid and ComboBox all with ItemsSource to the same collection, and the same SeletedItem.

As you change selected Person, you will see all three controls change together.

A TextBox and TextBlock share the same property, and changes in the TextBox reflect in the TextBlock.

Click the button to add a user, it shows in all three controls.

Closing the Window is just a nasty code behind hack, the simplest and worst of the examples.

## **Window1 - DataContext set from CodeBehind**

![](http://i1.gallery.technet.s-msft.com/easy-mvvm-examples-48c94de3/image/file/66212/1/mvvm2.png)

This window simply shows how you can attach the ViewModel to the DataContext in code, done by MainWindow.

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>C#</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">csharp</span>

<pre class="hidden">var win = new Window1 { DataContext = new ViewModelWindow1(tb1.Text) };</pre>

<div class="preview">

<pre class="js"><span class="js__statement">var</span> win = <span class="js__operator">new</span> Window1 <span class="js__brace">{</span> DataContext = <span class="js__operator">new</span> ViewModelWindow1(tb1.Text) <span class="js__brace">}</span>;</pre>

</div>

</div>

</div>

This ViewModel is derived from ViewModelMain, with an extra public property and command to pull from the base class and update the new property and UI.

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>XAML</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">xaml</span>

<pre class="hidden"><Button Content="Change Text" Command="{Binding ChangeTextCommand}" CommandParameter="{Binding SelectedItem, ElementName=dg1}"/></pre>

<div class="preview">

<pre class="js"><Button Content=<span class="js__string">"Change Text"</span> Command=<span class="js__string">"{Binding ChangeTextCommand}"</span> CommandParameter=<span class="js__string">"{Binding SelectedItem, ElementName=dg1}"</span>/></pre>

</div>

</div>

</div>

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>C#</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">csharp</span>

<pre class="hidden">void ChangeText(object selectedItem)
{
    //Setting the PUBLIC property 'TestText', so PropertyChanged event is fired
    if (selectedItem == null)
        TestText = "Please select a person"; 
    else
    {
        var person = selectedItem as Person;
        TestText = person.FirstName + " " + person.LastName;
    }
}</pre>

<div class="preview">

<pre class="js"><span class="js__operator">void</span> ChangeText(object selectedItem) 
<span class="js__brace">{</span> 
    <span class="js__sl_comment">//Setting the PUBLIC property 'TestText', so PropertyChanged event is fired</span> 
    <span class="js__statement">if</span> (selectedItem == null) 
        TestText = <span class="js__string">"Please select a person"</span>;  
    <span class="js__statement">else</span> 
    <span class="js__brace">{</span> 
        <span class="js__statement">var</span> person = selectedItem as Person; 
        TestText = person.FirstName + <span class="js__string">" "</span> + person.LastName; 
    <span class="js__brace">}</span> 
<span class="js__brace">}</span></pre>

</div>

</div>

</div>

You can see I'm having to check for null here, "boiler plating" we could do without, as shown in CanExecute below.

Closing this Window uses the nicest way to do it, using an Attached Behaviour (Property) with a binding to a flag in the ViewModelBase. In our ViewModel we simply call CloseWindow()

## **Window 2 - Using DependencyObject instead of INPC**

![](http://i1.gallery.technet.s-msft.com/easy-mvvm-examples-48c94de3/image/file/66213/1/mvvm3.png)

This example shows the alternative to INotifyPropertyChanged - DependencyObject and Dependency Properties.

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>C#</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">csharp</span>

<pre class="hidden">public Person SelectedPerson
{
    get { return (Person)GetValue(SelectedPersonProperty); }
    set { SetValue(SelectedPersonProperty, value); }
}

// Using a DependencyProperty as the backing store for SelectedPerson.  This enables animation, styling, binding, etc...
public static readonly DependencyProperty SelectedPersonProperty =
    DependencyProperty.Register("SelectedPerson", typeof(Person), typeof(ViewModelWindow2), new UIPropertyMetadata(null));</pre>

<div class="preview">

<pre class="js">public Person SelectedPerson 
<span class="js__brace">{</span> 
    get <span class="js__brace">{</span> <span class="js__statement">return</span> (Person)GetValue(SelectedPersonProperty); <span class="js__brace">}</span> 
    set <span class="js__brace">{</span> SetValue(SelectedPersonProperty, value); <span class="js__brace">}</span> 
<span class="js__brace">}</span> 

<span class="js__sl_comment">// Using a DependencyProperty as the backing store for SelectedPerson.  This enables animation, styling, binding, etc...</span> 
public static readonly DependencyProperty SelectedPersonProperty = 
    DependencyProperty.Register(<span class="js__string">"SelectedPerson"</span>, <span class="js__operator">typeof</span>(Person), <span class="js__operator">typeof</span>(ViewModelWindow2), <span class="js__operator">new</span> UIPropertyMetadata(null));</pre>

</div>

</div>

</div>

<div class="endscriptcode">Dependency Properties also fire PropertyChanged events, and also have callback and coerce delegates.</div>

The only drawback to Dependency Properties for general MVVM use is they need to be handled on the UI layer.

This example also shows how a command can also control if a button is enabled, through it's CanExecute delegate.

As we are not using the parameter, but relyng on the ViewModel selected item, if there is none, the CanExecute method returns false, which disables the button. All done by behaviour, no messy code or boiler plating.

<div class="scriptcode">

<div class="pluginEditHolder" plugincommand="mceScriptCode">

<div class="title"><span>C#</span></div>

<div class="pluginLinkHolder"><span class="pluginEditHolderLink">Edit</span>|<span class="pluginRemoveHolderLink">Remove</span></div>

<span class="hidden">csharp</span>

<pre class="hidden">public ViewModelWindow2()
{
    People = FakeDatabaseLayer.GetPeopleFromDatabase();
    NextExampleCommand = new RelayCommand(NextExample, NextExample_CanExecute);
}

bool NextExample_CanExecute(object parameter)
{
    return SelectedPerson != null;
}</pre>

<div class="preview">

<pre class="csharp"><span class="cs__keyword">public</span> ViewModelWindow2() 
{ 
    People = FakeDatabaseLayer.GetPeopleFromDatabase(); 
    NextExampleCommand = <span class="cs__keyword">new</span> RelayCommand(NextExample, NextExample_CanExecute); 
} 

<span class="cs__keyword">bool</span> NextExample_CanExecute(<span class="cs__keyword">object</span> parameter) 
{ 
    <span class="cs__keyword">return</span> SelectedPerson != <span class="cs__keyword">null</span>; 
}</pre>

</div>

</div>

</div>

<div class="endscriptcode">In this example, we still use the Attached Property in the Window XAML, to close the Window, but the property is another Dependency Property in the ViewModel.</div>

## **Window 3 - Using a POCO object in the ViewModel**

<div class="endscriptcode">![](http://i1.gallery.technet.s-msft.com/easy-mvvm-examples-48c94de3/image/file/66214/1/mvvm4.png)</div>

<div class="endscriptcode">A POCO class in WPF/MVVM terms is one that does not provide any PropertyChanged events. This would usually be legacy code modules, or converting from WinForms.</div>

<div class="endscriptcode">If a POCO class is used in the classic INPC setup, things start to go wrong.</div>

<div class="endscriptcode">At first, everything seems fine. Selected item is updated in all, you can change properties of existing people, and add new people through the DataGrid.</div>

<div class="endscriptcode">However, the textbox should actually be showing a timestamp, as set by the code behind Dispatcher Timer.</div>

<div class="endscriptcode">Also, clicking the button to add a new person does not seem to work, until you try to add a user in the DataGrid.</div>

## **Window 4 - Fixing with INPC for one property**

<div class="endscriptcode">![](http://i1.gallery.technet.s-msft.com/easy-mvvm-examples-48c94de3/image/file/66215/1/mvvm4.png)</div>

<div class="endscriptcode">This example is simply an extension to the previous example, where I have added the ViewModelBase and PropertyChanged event on the timer property. Now you can see the time updating.</div>

## **Window 5 - How to consume a closed Business Object (database layer, web service)**

<div class="endscriptcode">![](http://i1.gallery.technet.s-msft.com/easy-mvvm-examples-48c94de3/image/file/66216/1/mvvm6.png)</div>

<div class="endscriptcode">What if you have a business object that handles all the work, like a database layer or web service?</div>

<div class="endscriptcode">This may therefore be a closed object that you cannot enrich with INPC on it's properties.</div>

<div class="endscriptcode">In this case you have to fall back on wrappers and polling.</div>

<div class="endscriptcode">This example shows a complete and virtually codeless master/detail, edit & add control.</div>

For a full discussion and detailed breakdown of this project, please read below:

<span style="font-size:small">**[http://social.technet.microsoft.com/wiki/contents/articles/13536.easy-mvvm-examples.aspx](http://social.technet.microsoft.com/wiki/contents/articles/13536.easy-mvvm-examples.aspx)**</span>

</div>