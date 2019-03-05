#include "FrmStickyList.h"
#include "ui_FrmStickyList.h"
#include "Global/GlobalDir.h"
#include "StickyItemDelegate.h"
#include <QFileDialog>
#include <QSettings>
#include <QDebug>


CFrmStickyList::CFrmStickyList(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::CFrmStickyList),
    m_Model(this)
{
    ui->setupUi(this);
    ui->listView->setModel(&m_Model);
    ui->listView->setContextMenuPolicy(Qt::ActionsContextMenu);
    ui->listView->addAction(ui->actionNew);
    ui->listView->addAction(ui->actionRemove);
    ui->listView->setItemDelegate(new CStickyItemDelegate(ui->listView));
    QSettings set(CGlobalDir::Instance()->GetUserConfigureFile(),
                  QSettings::IniFormat);
    QString szFile = set.value("Sticky/File",
                               CGlobalDir::Instance()->GetDirData()
                               + QDir::separator() + "Sticky").toString();
    Load(szFile);
    QSharedPointer<CSticky> s;
    int i = 0;
    while(s = m_Model.Get(i++))
    {
        CFrmStickyNotes* sn = NewFrmSticky(s);
        if(!s->GetWindowHide())
        {
            sn->show();            
        }
    }
}

CFrmStickyList::~CFrmStickyList()
{
    if(m_Model.IsModify())
    {    
        QSettings set(CGlobalDir::Instance()->GetUserConfigureFile(),
                      QSettings::IniFormat);
        QString szFile = set.value("Sticky/File",
                                   CGlobalDir::Instance()->GetDirData()
                                   + QDir::separator() + "Sticky").toString();
        Save(szFile);
    }
    foreach(CFrmStickyNotes* p, m_StickyNotes)
    {
        p->close();
        p->deleteLater();
    }
    m_StickyNotes.clear();
    delete ui;
}

void CFrmStickyList::slotLoad()
{
    QString szFile = QFileDialog::getOpenFileName();
    if(szFile.isEmpty())
        return;
    Load(szFile);
}

int CFrmStickyList::Load(const QString &szFile)
{
    QFile f(szFile);
    if(!f.open(QIODevice::ReadOnly))
    {
        qDebug() << "CFrmStickyList::Load file fail: " << szFile;
        return -1;
    }
    QDataStream d(&f);
    d >> m_Model;
    f.close();
    QSettings set(CGlobalDir::Instance()->GetUserConfigureFile(),
                  QSettings::IniFormat);
    set.value("Sticky/File", szFile);
    return 0;
}

void CFrmStickyList::slotSave()
{
    QString szFile = QFileDialog::getSaveFileName();
    if(szFile.isEmpty())
        return;
}

int CFrmStickyList::Save(const QString &szFile)
{
    QFile f(szFile);
    if(!f.open(QIODevice::WriteOnly))
    {
        qDebug() << "CFrmStickyList::Save file fail: " << szFile;
        return -1;
    }
    QDataStream d(&f);
    d << m_Model;
    f.close();
    return 0;
}

void CFrmStickyList::on_actionNew_triggered()
{
    QSharedPointer<CSticky> s = m_Model.Add();
    if(!s)
        return;
    s->SetContent(tr("Take notes ......"));
    CFrmStickyNotes* sn = NewFrmSticky(s);
    if(sn)
    {
        sn->show();
    }
}

CFrmStickyNotes* CFrmStickyList::NewFrmSticky(QSharedPointer<CSticky> s)
{
    CFrmStickyNotes* pStickyNote = new CFrmStickyNotes(nullptr, s);
    if(!pStickyNote)
        return nullptr;
    bool check = connect(pStickyNote, SIGNAL(sigNew()),
                         this, SLOT(on_actionNew_triggered()));
    Q_ASSERT(check);
    check = connect(s.data(), SIGNAL(sigRemove(QSharedPointer<CSticky>)),
                    this, SLOT(slotDelete(QSharedPointer<CSticky>)));
    Q_ASSERT(check);
    m_StickyNotes.push_back(pStickyNote);
    return pStickyNote;
}

void CFrmStickyList::on_actionRemove_triggered()
{
    QModelIndex index = ui->listView->currentIndex();
    m_Model.removeRow(index.row());
}

void CFrmStickyList::on_listView_doubleClicked(const QModelIndex &index)
{
    ShowSticky(index.row());
}

void CFrmStickyList::ShowSticky(int i)
{
   if(i < 0 || i >= m_StickyNotes.length())
       return;
   m_StickyNotes.at(i)->show();
   m_StickyNotes.at(i)->activateWindow();
}

void CFrmStickyList::slotDelete(QSharedPointer<CSticky> sticky)
{
    foreach(CFrmStickyNotes* s, m_StickyNotes)
    {
        if(s->IsSticky(sticky))
        {
            s->close();
            m_StickyNotes.removeOne(s);
            s->deleteLater();
            return;
        }
    }
}
