#include "FrmTasksList.h"
#include "TaskPromptDelay.h"
#include "ui_FrmTasksList.h"
#include "Global/GlobalDir.h"
#include <QModelIndex>
#include <QFileDialog>
#include <QMessageBox>
#include <QSettings>

CFrmTasksList::CFrmTasksList(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::CFrmTasksList)
{
    ui->setupUi(this);
    Init();
}

CFrmTasksList::~CFrmTasksList()
{
    delete ui;
}

int CFrmTasksList::Init()
{
    int nRet = 0;
    this->layout()->addWidget(&m_ToolBar);
    this->layout()->addWidget(&m_lvTasks);
    this->layout()->addWidget(&m_FrmTasks);
    
    m_lvTasks.setModel(&m_Model);
    m_FrmTasks.hide();
    bool check = connect(&m_FrmTasks, SIGNAL(Changed()),
                         this, SLOT(slotSaveAs()));
    Q_ASSERT(check);
    check = connect(&m_lvTasks, SIGNAL(doubleClicked(const QModelIndex)),
                         this, SLOT(on_lvTasks_clicked(const QModelIndex)));
    Q_ASSERT(check);
    m_ToolBar.addAction(ui->actionLoad_L);
    m_ToolBar.addAction(ui->actionSaveAs_S);
    m_ToolBar.addSeparator();
    m_ToolBar.addAction(ui->actionNew_N);
    m_ToolBar.addAction(ui->actionRemove_R);
    m_ToolBar.addAction(ui->actionRefresh_F);
    check = connect(ui->actionNew_N, SIGNAL(triggered()),
                         this, SLOT(slotNew()));
    Q_ASSERT(check);
    check = connect(ui->actionRemove_R, SIGNAL(triggered()),
                    this, SLOT(slotRemove()));
    Q_ASSERT(check);
    check = connect(ui->actionLoad_L, SIGNAL(triggered()),
                    this, SLOT(slotLoad()));
    Q_ASSERT(check);
    check = connect(ui->actionSaveAs_S, SIGNAL(triggered()),
                    this, SLOT(slotSaveAs()));
    Q_ASSERT(check);
    check = connect(ui->actionRefresh_F, SIGNAL(triggered()),
                    this, SLOT(slotRefresh()));
    Q_ASSERT(check);
    QSettings set(CGlobalDir::Instance()->GetUserConfigureFile(),
                  QSettings::IniFormat);
    QString szFile = set.value("TasksList").toString();
    nRet = Load(szFile);
    
    return nRet;
}

void CFrmTasksList::slotRefresh()
{
    int nIndex = 0;
    m_Model.clear();
    while(QSharedPointer<CTasks> p = m_TasksList.Get(nIndex++))
    {
        QStandardItem *title = new QStandardItem(p->GetIcon(), p->GetTitle());
        title->setToolTip(p->GetContent());
        m_Model.appendRow(title);
    }
    m_lvTasks.setCurrentIndex(m_Model.index(0, 0));
    //TODO: 
    m_TasksList.Start();
}

int CFrmTasksList::Load(QString szFile)
{
    int nRet = m_TasksList.LoadSettings(szFile);
    if(nRet)
        return nRet;
    
    slotRefresh();
    
    return m_TasksList.Start();
}

void CFrmTasksList::slotLoad()
{
    QFileDialog fd(this, tr("Load"), QString(), tr("xml(*.xml);;All files(*.*)"));
    fd.setFileMode(QFileDialog::ExistingFile);
    int n = fd.exec();
    if(QDialog::Rejected == n)
        return;
    Load(fd.selectedFiles().at(0));
}

void CFrmTasksList::slotSaveAs()
{
    QFileDialog fd(this, tr("Save as ..."), QString(), "*.xml");
    //fd.setFileMode(QFileDialog::AnyFile);
    fd.setAcceptMode(QFileDialog::AcceptSave);
    int n = fd.exec();
    if(QDialog::Rejected == n)
        return;
    QString szFile = fd.selectedFiles().at(0);
    if(szFile.lastIndexOf(".xml") == -1)
        szFile += ".xml";
    QDir d;
    if(d.exists(szFile))
    {
        QMessageBox::StandardButton n = QMessageBox::warning(this,
                          tr("File exist"),
                          tr("%1 is existed, replace it?").arg(szFile),
                          QMessageBox::Ok | QMessageBox::Cancel);
        if(QMessageBox::Ok != n)
            return;        
    }
    
    int nRet = m_TasksList.SaveSettings(szFile);
    if(0 == nRet)
    {
        QSettings set(CGlobalDir::Instance()->GetUserConfigureFile(),
                      QSettings::IniFormat);
        set.setValue("TasksList", szFile);
    }
    slotRefresh();
}

void CFrmTasksList::on_lvTasks_clicked(const QModelIndex &index)
{
    QSharedPointer<CTasks> p = m_TasksList.Get(index.row());
    if(nullptr == p)
    {
        m_FrmTasks.hide();
        return;
    }
    m_FrmTasks.SetTasks(p);
    m_FrmTasks.show();
}

void CFrmTasksList::slotNew()
{
    //TODO：增加一个常用任务的组合框列表供用户选择  
    QSharedPointer<CTasks> tasks(new CTasks());
    tasks->SetTitle(tr("New tasks"));
    tasks->SetIcon(QIcon(":/icon/App"));
    tasks->SetContent(tr("After 5 minutes, the prompt will show 5 minutes, repeat"));
    m_TasksList.Add(tasks);
    //TODO:如果这里是新的，原来没有开始过。是否增加重新开始菜单？  
    //m_TasksList.Start();
    QSharedPointer<CTask> task(new CTask(5 * 60 * 1000));
    task->SetTitle(tr("New task"));
    task->SetContent(tr("If the task is not you need, please select a task from combox, new it, and remove the task."));
    tasks->Add(task);
    QSharedPointer<CTask> taskPrompt(new CTaskPromptDelay());
    task->SetTitle(tr("New prompt task"));
    task->SetContent(tr("If the task is not you need, please select a task from combox, new it, and remove the task."));
    tasks->Add(taskPrompt);        
    QStandardItem *title = new QStandardItem(tasks->GetIcon(), tasks->GetTitle());
    title->setToolTip(tasks->GetContent());
    m_Model.appendRow(title);
    m_lvTasks.setCurrentIndex(m_Model.index(m_Model.rowCount() - 1, 0));
    on_lvTasks_clicked(m_lvTasks.currentIndex());
}

void CFrmTasksList::slotRemove()
{
    m_TasksList.Remove(m_TasksList.Get(m_lvTasks.currentIndex().row()));
    m_Model.removeRow(m_lvTasks.currentIndex().row());
    on_lvTasks_clicked(m_lvTasks.currentIndex());
}

void CFrmTasksList::on_lvTasks_indexesMoved(const QModelIndexList &indexes)
{
    QSharedPointer<CTasks> p = m_TasksList.Get(indexes.at(0).row());
    if(nullptr == p)
        return;
    m_FrmTasks.SetTasks(p);
    m_FrmTasks.show();
}

void CFrmTasksList::closeEvent(QCloseEvent *event)
{
    Q_UNUSED(event);
    m_TasksList.RemoveAll();
}